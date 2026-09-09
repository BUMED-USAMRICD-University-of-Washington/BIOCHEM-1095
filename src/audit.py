SET search_path TO virustc_core, public;

-- =====================================================================
-- SYSTEM ACCESS AND TRANSACTION AUDIT MATRIX
-- =====================================================================
CREATE TABLE IF NOT EXISTS security_audit_logs (
    audit_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL, -- Tracks the authenticated operational profile
    system_role VARCHAR(50), -- Captures active clearance parameters at execution
    request_method VARCHAR(10) NOT NULL, -- GET, POST, PUT, DELETE
    endpoint_path VARCHAR(255) NOT NULL, -- Target API component
    sql_action_type VARCHAR(20) NOT NULL, -- READ, INSERT, UPDATE, DELETE, SYSTEM
    client_ip VARCHAR(45), -- Supports tracking across IPv4 and IPv6 topologies
    lot_number_context VARCHAR(50), -- Extract tracking entity context dynamically
    execution_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_code INT NOT NULL -- Tracks success (200/202) or rejection matrices (401/403)
);

-- Indexing parameters for fast system searches across huge data tables
CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON security_audit_logs(execution_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_username ON security_audit_logs(username);
CREATE INDEX IF NOT EXISTS idx_audit_lot ON security_audit_logs(lot_number_context);
