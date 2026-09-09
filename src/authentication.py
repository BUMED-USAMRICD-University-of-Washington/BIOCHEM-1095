import os
import psycopg2
from psycopg2.extras import RealDictCursor
from datetime import datetime, timedelta
from typing import Optional, Dict, Any
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

# Initialize system configuration paths
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://vtc_admin:SecureCryptoPass2026@localhost:5432/virustc_compliance")
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7")
ALGORITHM = "HS256"

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

class User(BaseModel):
    username: str
    email: str
    full_name: str
    is_disabled: bool

def get_db_connection():
    """Establishes thread-safe transactional database connection handles."""
    return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)

# =====================================================================
# NEW POSTGRESQL AUTHENTICATION INGESTION BACKEND
# =====================================================================

def get_user_from_database(username: str) -> Optional[Dict[str, Any]]:
    """
    Queries the persistent user repository table inside the virustc_core schema 
    to retrieve the corresponding structural identity metadata matrix.
    """
    query = "SELECT username, email, full_name, hashed_password, is_disabled FROM virustc_core.system_users WHERE username = %s;"
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (username,))
            return cursor.fetchone()
    except Exception as e:
        print(f"[AUTH DATABASE READ FAULT] Failed to query user record: {e}")
        return None
    finally:
        conn.close()

async def get_current_active_user(token: str = Depends(oauth2_scheme)) -> User:
    """
    Route Gatekeeper. Decodes runtime tokens and verifies parameters against the 
    live production user database to prevent session exploitation.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials structure.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user_record = get_user_from_database(username)
    if user_record is None:
        raise credentials_exception
    if user_record["is_disabled"]:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="Administrative profile locked.")

    return User(
        username=user_record["username"],
        email=user_record["email"],
        full_name=user_record["full_name"],
        is_disabled=user_record["is_disabled"]
    )

@app.post("/api/v1/auth/token", response_model=Dict[str, str])
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    Verifies supplied user access forms straight against salted bcrypt strings 
    housed inside your PostgreSQL deployment instance.
    """
    user_record = get_user_from_database(form_data.username)
    if not user_record or not pwd_context.verify(form_data.password, user_record["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password configuration matrix.",
            headers={"WWW-Authenticate": "Bearer"},
        )

    access_token = jwt.encode(
        {"sub": user_record["username"], "exp": datetime.utcnow() + timedelta(minutes=60)},
        SECRET_KEY,
        algorithm=ALGORITHM
    )
    return {"access_token": access_token, "token_type": "bearer"}
