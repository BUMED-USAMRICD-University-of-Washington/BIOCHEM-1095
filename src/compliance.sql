SET search_path TO virustc_core, public;

-- =====================================================================
-- DETECT MALICIOUS CLUSTERS BY SUBNET RANGE
-- =====================================================================
SELECT 
    -- Casts text to network type, truncates host bits, and outputs as Class C CIDR text
    text(set_masklen(client_ip::inet, 24)) AS target_subnet_range,
    COUNT(*) AS total_blocked_intrusion_attempts,
    COUNT(DISTINCT username) AS unique_credential_identities_spoofed,
    COUNT(DISTINCT endpoint_path) AS distinct_api_endpoints_targeted,
    MAX(execution_timestamp) AS latest_recorded_threat_timestamp,
    
    -- Provides visibility into which specific error flags were triggered
    SUM(CASE WHEN status_code = 401 THEN 1 ELSE 0 END) AS total_401_authentication_rejections,
    SUM(CASE WHEN status_code = 403 THEN 1 ELSE 0 END) AS total_403_clearance_violations
FROM security_audit_logs
WHERE status_code IN (401, 403) -- Target unauthorized footprints exclusively [1]
GROUP BY set_masklen(client_ip::inet, 24)
HAVING COUNT(*) >= 5 -- Filters out accidental human key-entry drift blocks
ORDER BY total_blocked_intrusion_attempts DESC;
