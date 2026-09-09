import json
from fastapi import Request, Response
from starlette.middleware.base import BaseHTTPMiddleware

class VirusTCAuditMiddleware(BaseHTTPMiddleware):
    """
    Automated interceptor engine logging access metrics, endpoint hits, 
    and transaction statuses straight into the structural database repository.
    """
    async def dispatch(self, request: Request, call_next):
        # 1. Capture inbound connection environment parameters
        client_ip = request.client.host if request.client else "0.0.0.0"
        path = request.url.path
        method = request.method
        
        # Determine the general database transaction category based on the HTTP method structure
        sql_action_map = {"GET": "READ", "POST": "INSERT", "PUT": "UPDATE", "DELETE": "DELETE"}
        sql_action = sql_action_map.get(method, "SYSTEM")

        # 2. Extract operational security context if available
        username = "UNAUTHENTICATED"
        system_role = "UNKNOWN"
        lot_context = None

        # Inspect authorization header fragments without prematurely crashing the route sequence
        auth_header = request.headers.get("Authorization")
        if auth_header and auth_header.startswith("Bearer "):
            try:
                token = auth_header.split(" ")[1]
                payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
                username = payload.get("sub", "UNAUTHENTICATED")
                
                # Fetch role parameters straight from the DB to preserve audit trail integrity
                user_meta = get_user_from_database(username)
                if user_meta:
                    system_role = "DETERMINED_VIA_RBAC" # Extracted during route processing
            except Exception:
                username = "INVALID_TOKEN_ATTEMPT"

        # 3. Process the underlying system endpoint
        try:
            response: Response = await call_next(request)
            status_code = response.status_code
        except Exception as e:
            status_code = 500
            raise e
        finally:
            # Skip noise routes like standard open documentation configurations
            if not path.startswith(("/docs", "/openapi.json", "/favico")):
                self.commit_audit_entry(
                    username=username,
                    role=system_role,
                    method=method,
                    path=path,
                    action=sql_action,
                    ip=client_ip,
                    lot=lot_context,
                    status=status_code
                )
        return response

    def commit_audit_entry(self, username: str, role: str, method: str, path: str, 
                           action: str, ip: str, lot: str, status: int):
        """Executes an immutable asynchronous data insert to record the security state."""
        query = """
            INSERT INTO virustc_core.security_audit_logs 
            (username, system_role, request_method, endpoint_path, sql_action_type, client_ip, lot_number_context, status_code)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s);
        """
        try:
            conn = psycopg2.connect(DATABASE_URL)
            with conn:
                with conn.cursor() as cursor:
                    cursor.execute(query, (username, role, method, path, action, ip, lot, status))
        except Exception as e:
            print(f"[SECURITY AUDIT FAILURE] Log failure occurred to write event record to storage: {e}")
        finally:
            conn.close()

# Activate the logging engine within your FastAPI microservice stack
app.add_middleware(VirusTCAuditMiddleware)
