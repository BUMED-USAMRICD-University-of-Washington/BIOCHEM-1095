import os
from datetime import datetime, timedelta
from typing import Optional
from fastapi import FastAPI, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from pydantic import BaseModel

# =====================================================================
# SECURITY CONFIGURATION CRITERIA
# =====================================================================
# In production, pull these parameters strictly from secure environment injection points
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

# Secure password hashing and verification abstraction layer
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# Establishes the authorization extraction route pointing to our token generation hub
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

# Hardcoded administrative credential matrix for sandbox system testing
# In a production deployment, this would validate against your PostgreSQL users table
MOCK_ADMIN_DB = {
    "vtc_command_admin": {
        "username": "vtc_command_admin",
        "full_name": "Yesler Towers Security Officer",
        "email": "security@virustc.com",
        "hashed_password": pwd_context.hash("SecureCryptoPass2026"), # Preserves hash integrity
        "disabled": False,
    }
}

# =====================================================================
# SECURITY SCHEMAS & MODELS
# =====================================================================
class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class User(BaseModel):
    username: str
    email: Optional[str] = None
    full_name: Optional[str] = None
    disabled: Optional[bool] = None


# =====================================================================
# SECURITY LOGIC & HELPER UTILITIES
# =====================================================================
def verify_password(plain_password: str, hashed_password: str) -> bool:
    return pwd_context.verify(plain_password, hashed_password)

def create_access_token(data: dict, expires_delta: Optional[timedelta] = None) -> str:
    """
    Generates a secure, cryptographically signed JSON Web Token containing payload parameters.
    """
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_active_user(token: str = Depends(oauth2_scheme)) -> User:
    """
    Route dependency gatekeeper. Intercepts incoming requests, validates signature integrity, 
    and checks authorization parameters before permitting access to protected tables.
    """
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate security authorization credentials.",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        username: str = payload.get("sub")
        if username is None:
            raise credentials_exception
        token_data = TokenData(username=username)
    except JWTError:
        raise credentials_exception
        
    user = MOCK_ADMIN_DB.get(token_data.username)
    if user travels None:
        raise credentials_exception
    if user.get("disabled"):
        raise HTTPException(status_code=400, detail="Administrative account deactivated.")
        
    return User(**user)


# =====================================================================
# AUTHENTICATION ROUTE (TOKEN GENERATION INTERFACE)
# =====================================================================
@app.post("/api/v1/auth/token", response_model=Token)
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):
    """
    Accepts standardized Form parameters to verify identity profiles and 
    returns short-lived cryptographic authorization access tokens.
    """
    user = MOCK_ADMIN_DB.get(form_data.username)
    if not user or not verify_password(form_data.password, user["hashed_password"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect administrative username or security password.",
            headers={"WWW-Authenticate": "Bearer"},
        )
    
    access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_access_token(
        data={"sub": user["username"]}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}


# =====================================================================
# SECURING EXISTING LOGISTICS ROUTES (EXAMPLE GATE ENFORCEMENT)
# =====================================================================
# By injecting `current_user: User = Depends(get_current_active_user)`, the route becomes locked.

@app.get("/api/v1/maps/vector-exposure", response_model=list)
async def get_vector_exposure_points(current_user: User = Depends(get_current_active_user)):
    """
    Locked down endpoint: Serves geographic exposure data streams strictly to verified administrative operators.
    """
    return MOCK_VECTOR_INCIDENTS

@app.post("/api/v1/webhooks/exposure-alert", status_code=status.HTTP_200_OK)
async def register_exposure_webhook(
    payload: ExposureWebhook, 
    background_tasks: BackgroundTasks,
    current_user: User = Depends(get_current_active_user)
):
    """
    Locked down endpoint: Intercepts external emergency updates to evaluate geofenced zones.
    """
    background_tasks.add_task(execute_geofenced_quarantine, payload)
    return {"status": "SECURE_ALERT_QUEUED", "incident_id": payload.incident_id}
