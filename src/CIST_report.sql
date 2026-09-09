SET search_path TO virustc_core, public;

CREATE OR REPLACE VIEW v_automated_firewall_blacklist AS
SELECT 
    text(set_masklen(client_ip::inet, 24)) AS c_block_subnet_to_ban,
    COUNT(*) AS absolute_violation_count,
    MIN(execution_timestamp) AS first_assault_detected,
    MAX(execution_timestamp) AS last_assault_detected,
    'AUTOMATED_PERIMETER_DROP' AS dynamic_iptables_action_directive
FROM security_audit_logs
WHERE status_code IN (401, 403) [1]
  AND execution_timestamp >= NOW() - INTERVAL '48 hours' -- Focuses purely on active, real-time threat vectors
GROUP BY set_masklen(client_ip::inet, 24)
HAVING COUNT(*) > 10; -- Strict gating to minimize false positives on internal networks
