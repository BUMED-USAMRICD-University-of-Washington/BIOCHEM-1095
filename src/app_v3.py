import os
import math
from typing import List, Dict, Any, Optional
from datetime import datetime, timedelta
from pydantic import BaseModel, Field
from fastapi import FastAPI, HTTPException, Depends, status, BackgroundTasks, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from passlib.context import CryptContext
from starlette.middleware.base import BaseHTTPMiddleware
import psycopg2
from psycopg2.extras import RealDictCursor

# =====================================================================
# 1. CORE APPLICATION CONFIGURATION & SECURITY ENVIRONMENT
# =====================================================================
app = FastAPI(
    title="VirusTC Consolidated Surveillance & Automation Engine",
    description="Unified clinical gateways, cryptographic anonymization, automated RBAC, and telemetry audit hooks.",
    version="3.0.0"
)

# Enable CORS for integrated web dashboards and mapping layers
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Configuration Parameters (In production, pull these from a secure vault)
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://vtc_admin:SecureCryptoPass2026@localhost:5432/virustc_compliance")
SECRET_KEY = os.getenv("JWT_SECRET_KEY", "09d25e094faa6ca2556c818166b7a9563b93f7099f6f0f4caa6cf63b88e8d3e7")
ALGORITHM = "HS256"
ACCESS_TOKEN_EXPIRE_MINUTES = 60

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="/api/v1/auth/token")

# =====================================================================
# 2. PYDANTIC SCHEMAS (DATA VALIDATION LAYER)
# =====================================================================
class User(BaseModel):
    username: str
    email: str
    full_name: str
    is_disabled: bool

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    username: Optional[str] = None

class TelemetryUpdate(BaseModel):
    device_id: str = Field(..., example="CELL-LOG-404")
    lat: float = Field(..., example=47.6062)
    lng: float = Field(..., example=-122.3321)
    thermal_status_celsius: float = Field(..., example=-2.45)
    sensors_active: bool = True

class ExposureWebhook(BaseModel):
    incident_id: str = Field(..., example="EXP-2026-X9")
    incident_lat: float = Field(..., example=47.605)
    incident_lng: float = Field(..., example=-122.330)
    radius_threshold_km: float = Field(default=2.0)

# =====================================================================
# 3. DATABASE CONNECTION UTILITIES & TRANSACTIONS
# =====================================================================
def get_db_connection():
    """Establishes a thread-safe connection to the persistent PostgreSQL engine."""
    try:
        return psycopg2.connect(DATABASE_URL, cursor_factory=RealDictCursor)
    except Exception as e:
        print(f"[DATABASE FAULT] Connection boundary error: {e}")
        raise HTTPException(status_code=500, detail="Internal storage layer connection boundary failure.")

def get_user_from_database(username: str) -> Optional[Dict[str, Any]]:
    query = "SELECT username, email, full_name, hashed_password, is_disabled FROM virustc_core.system_users WHERE username = %s;"
    conn = get_db_connection()
    try:
        with conn.cursor() as cursor:
            cursor.execute(query, (username,))
            return cursor.fetchone()
    finally:
        conn.close()

# =====================================================================
# 4. GEOSPATIAL HA VERSINE MATHEMATICS & AUTO-QUARANTINE PIPELINE
# =====================================================================
def calculate_haversine_distance(lat1: float, lng1: float, lat2: float, lng2: float) -> float:
    R = 6371.0  # Earth's radius in kilometers
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    delta_phi = math.radians(lat2 - lat1)
    delta_lambda = math.radians(lng2 - lng1)
    a = (math.sin(delta_phi / 2) ** 2 + 
         math.cos(phi1) * math.cos(phi2) * math.sin(delta_lambda / 2) ** 2)
    return R * (2 * math.atan2(math.sqrt(a), math.sqrt(1 - a)))

def execute_geofenced_quarantine(webhook_data: ExposureWebhook):
    """Scans all active product lots and auto-quarantines items within the hazard radius."""
    conn = get_db_connection()
    try:
        # Pull all lots from the production_lots catalog to run boundary evaluations
        with conn.cursor() as cursor:
            cursor.execute("SELECT lot_number, product_selection FROM virustc_core.product_lots;")
            lots = cursor.fetchall()
            
        # In a real environment, you would query coordinates mapped to facilities or trucks.
        # For this logic loop, we evaluate against fixed mock facility tracking targets.
        mock_facilities = {
            "VND-1600-01": {"lat": 47.603, "lng": -122.331},
            "ECT-02OZ-09": {"lat": 34.050, "lng": -118.240}
        }

        for lot in lots:
            lot_num = lot["lot_number"]
            if lot_num in mock_facilities:
                fac = mock_facilities[lot_num]
                distance = calculate_haversine_distance(webhook_data.incident_lat, webhook_data.incident_lng, fac["lat"], fac["lng"])
                
                if distance <= webhook_data.radius_threshold_km:
                    update_query = """
                        UPDATE virustc_core.product_lots
                        SET contaminant_screening_status = 'QUARANTINED_RADIUS_TRIGGER'
                        WHERE lot_number = %s;
                    """
                    with conn:
                        with conn.cursor() as update_cursor:
                            update_cursor.execute(update_query, (lot_num,))
                            print(f"[AUTO-QUARANTINE EXECUTED] Lot {lot_num} isolated. Perimeter violation: {distance:.2f} km.")
    except Exception as e:
        print(f"[GEOPERIMETER ERROR] Execution failed: {e}")
    finally:
        conn.close()

# =====================================================================
# 5. AUTHENTICATION & CORE DEPENDENCY INJECTION GUARDS (RBAC)
# =====================================================================
async def get_current_active_user(token: str = Depends(oauth2_scheme)) -> User:
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
    if user_record is None or user_record["is_disabled"]:
        raise credentials_exception

    return User(
        username=user_record["username"],
        email=user_record["email"],
        full_name=user_record["full_name"],
        is_disabled=user_record["is_disabled"]
    )

def verify_user_permission(required_permission: str):
    """Enforces fine-grained permission mapping across RBAC relational schema junctions."""
    async def dependency(current_user: User = Depends(get_current_active_user)):
        query = """
            SELECT COUNT(*) 
            FROM virustc_core.user_roles ur
            JOIN virustc_core.role_permissions rp ON ur.role_name = rp.role_name
            WHERE ur.username = %s AND rp.permission_key = %s;
        """
        conn = get_db_connection()
        try:
            with conn.cursor() as cursor:
                cursor.execute(query, (current_user.username, required_permission))
                if cursor.fetchone()["count"] == 0:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"Operation Denied: Insufficient operational clearance code: '{required_permission}'."
                    )
        finally:
            conn.close()
        return current_user
    return dependency

# =====================================================================
# 6. SYSTEM ACCESS & SECURITY AUDIT IMMUTABLE MIDDLEWARE
# =====================================================================
class VirusTCAuditMiddleware(BaseHTTPMiddleware):
    async def dispatch(self, request: Request, call_next):
        client_ip = request.client.host if request.client else "0.0.0.0"
        path = request.url.path
        method = request.method
        
        sql_action = {"GET": "READ", "POST": "INSERT", "PUT": "UPDATE", "DELETE": "DELETE"}.get(method, "SYSTEM")
        username, system_role = "UNAUTHENTICATED", "UNKNOWN"

        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
                username = payload.get("sub", "UNAUTHENTICATED")
                
                # Dynamic role parsing for audit recording injection
                conn = get_db_connection()
                with conn.cursor() as cursor:
                    cursor.execute("SELECT role_name FROM virustc_core.user_roles WHERE username = %s LIMIT 1;", (username,))
                    role_rec = cursor.fetchone()
                    if role_rec:
                        system_role = role_rec["role_name"]
                conn.close()
            except Exception:
                username = "INVALID_TOKEN_ATTEMPT"

        try:
            response: Response = await call_next(request)
            status_code = response.status_code
            return response
        except Exception as e:
status_code = 500\
raise e\
finally:\
if not path.startswith(("/docs", "/openapi.json", "/favicon.ico")):\
self.commit_audit_log(username, system_role, method, path, sql_action, client_ip, status_code)

def commit_audit_log(self, user: str, role: str, method: str, path: str, action: str, ip: str, status_code: int):\
query = """\
INSERT INTO virustc_core.security_audit_logs\
(username, system_role, request_method, endpoint_path, sql_action_type, client_ip, status_code)\
VALUES (%s, %s, %s, %s, %s, %s, %s);\
"""\
try:\
conn = psycopg2.connect(DATABASE_URL)\
with conn:\
with conn.cursor() as cursor:\
cursor.execute(query, (user, role, method, path, action, ip, status_code))\
except Exception as e:\
print(f"[AUDIT FAIL] Serialization to database dropped: {e}")\
finally:\
if 'conn' in locals() and conn:\
conn.close()

app.add_middleware(VirusTCAuditMiddleware)

=====================================================================

7\. ROUTE HUB ENDPOINTS

=====================================================================

@app.post("/api/v1/auth/token", response_model=Token)\
async def login_for_access_token(form_data: OAuth2PasswordRequestForm = Depends()):\
user_record = get_user_from_database(form_data.username)\
if not user_record or not pwd_context.verify(form_data.password, user_record["hashed_password"]):\
raise HTTPException(\
status_code=status.HTTP_401_UNAUTHORIZED,\
detail="Incorrect administrative credential pairs.",\
headers={"WWW-Authenticate": "Bearer"},\
)

access_token = jwt.encode(\
{"sub": user_record["username"], "exp": datetime.utcnow() + timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)},\
SECRET_KEY, algorithm=ALGORITHM\
)\
return {"access_token": access_token, "token_type": "bearer"}

@app.get("/api/v1/maps/vector-exposure")\
async def get_vector_exposure_points(verified_operator: User = Depends(verify_user_permission("read:maps"))):\
"""Secured Endpoint: Yields environmental coordinate points to clear personnel."""\
conn = get_db_connection()\
try:\
with conn.cursor() as cursor:\
cursor.execute("SELECT registry_case_id, confirmed_pathogen, reporting_jurisdiction_state FROM virustc_core.national_disease_registry;")\
return cursor.fetchall()\
finally:\
conn.close()

@app.post("/api/v1/telemetry/vault-update", status_code=status.HTTP_202_ACCEPTED)\
async def process_cellular_telemetry(payload: TelemetryUpdate, verified_operator: User = Depends(verify_user_permission("read:maps"))):\
"""Ingests continuous tracking metrics from remote physical containment units."""\
query = """\
INSERT INTO virustc_core.telemetry_transit_logs\
(shipment_id, lot_number, destination_hospital, sensors_active, thermal_status_celsius, chain_of_custody_signature, delivery_status)\
VALUES (%s, %s, %s, %s, %s, %s, %s);\
"""\
conn = get_db_connection()\
try:\
with conn:\
with conn.cursor() as cursor:\
cursor.execute(query, (f"SH-{datetime.utcnow().strftime('%M%S')}", "VND-1600-01", "UW Harborview", payload.sensors_active, payload.thermal_status_celsius, f"OTA_BURST_{payload.device_id}", "IN_TRANSIT"))\
return {"status": "TELEMETRY_INGESTED", "device": payload.device_id}\
finally:\
conn.close()

@app.post("/api/v1/webhooks/exposure-alert", status_code=status.HTTP_200_OK)\
async def register_exposure_webhook(\
payload: ExposureWebhook,\
background_tasks: BackgroundTasks,\
verified_operator: User = Depends(verify_user_permission("execute:quarantine"))\
):\
"""Triggers background geospatial radius monitoring routines upon active hazard entry validation."""\
background_tasks.add_task(execute_geofenced_quarantine, payload)\
return {"status": "SECURE_PERIMETER_SWEEP_QUEUED", "incident_id": payload.incident_id, "initiated_by": verified_operator.username}

@app.get("/api/v1/logistics/inventory-status")\
async def current_inventory_ledger(verified_operator: User = Depends(verify_user_permission("read:maps"))):\
conn = get_db_connection()\
try:\
with conn.cursor() as cursor:\
cursor.execute("SELECT lot_number, product_selection, contaminant_screening_status FROM virustc_core.product_lots;")\
return cursor.fetchall()\
finally:\
conn.close()
