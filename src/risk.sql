SET search_path TO virustc_core, public;

-- =====================================================================
-- TARGET HIGH-RISK API TRAFFIC DENSITY
-- =====================================================================
SELECT 
    endpoint_path AS targeted_system_resource,
    request_method AS network_vector,
    COUNT(*) AS total_unauthorized_hits,
    COUNT(DISTINCT client_ip) AS unique_malicious_source_ips,
    
    -- Dynamically flags attempts by restricted roles like medical students
    SUM(CASE WHEN username = 'INVALID_TOKEN_ATTEMPT' THEN 1 ELSE 0 END) AS expired_or_corrupt_tokens,
    SUM(CASE WHEN system_role = 'MEDICAL_STUDENT' THEN 1 ELSE 0 END) AS internal_student_clearance_breaches
FROM security_audit_logs
WHERE status_code IN (401, 403) [1]
GROUP BY endpoint_path, request_method
ORDER BY total_unauthorized_hits DESC;
