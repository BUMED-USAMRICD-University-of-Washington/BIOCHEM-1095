def verify_user_permission(required_permission: str):
    """
    Dependency Injection provider checking live user permissions against 
    relational schema matrices prior to executing protected endpoints.
    """
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
                has_access = cursor.fetchone()["count"] > 0
                if not has_access:
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"Operation Denied: Missing clearance: '{required_permission}'."
                    )
        finally:
            conn.close()
        return current_user
    return dependency

# =====================================================================
# LOCKED ENDPOINT ASSIGNMENT CONFIGURATION EXAMPLE
# =====================================================================
@app.post("/api/v1/webhooks/exposure-alert", status_code=status.HTTP_200_OK)
async def register_exposure_webhook(
    payload: ExposureWebhook, 
    background_tasks: BackgroundTasks,
    # Enforces role verification: Medical students cannot perform geofenced isolation actions
    verified_operator: User = Depends(verify_user_permission("execute:quarantine"))
):
    background_tasks.add_task(execute_geofenced_quarantine, payload)
    return {"status": "PERMITTED_ACTION_QUEUED", "operator": verified_operator.username}
