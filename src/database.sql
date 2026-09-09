-- =====================================================================
-- VIRUSTC COMPLIANCE, SURVEILLANCE & LOGISTICS INTEGRATED DATABASE CORE
-- =====================================================================
CREATE SCHEMA IF NOT EXISTS virustc_core;
SET search_path TO virustc_core, public;

-- =====================================================================
-- SECTION 1: CLINICAL PROVIDER GATING & JURISDICTIONS
-- =====================================================================
CREATE TABLE IF NOT EXISTS providers (
    provider_npi VARCHAR(10) PRIMARY KEY CHECK (LENGTH(provider_npi) = 10),
    provider_name VARCHAR(255) NOT NULL,
    home_state CHAR(2) NOT NULL,
    compact_license_active BOOLEAN DEFAULT FALSE,
    dea_registration_status VARCHAR(50) NOT NULL,
    credentialing_status VARCHAR(50) NOT NULL CHECK (credentialing_status IN ('APPROVED', 'PENDING_RENEWAL', 'UNDER_SUPERVISION', 'REVOKED'))
);

CREATE TABLE IF NOT EXISTS provider_licensed_states (
    provider_npi VARCHAR(10) REFERENCES providers(provider_npi) ON DELETE CASCADE,
    licensed_state CHAR(2) NOT NULL,
    expiration_date DATE NOT NULL,
    PRIMARY KEY (provider_npi, licensed_state)
);

-- =====================================================================
-- SECTION 2: SYSTEM USER REGISTRY & SECURITY PARAMS
-- =====================================================================
CREATE TABLE IF NOT EXISTS system_users (
    username VARCHAR(100) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    full_name VARCHAR(255) NOT NULL,
    hashed_password VARCHAR(255) NOT NULL,
    is_disabled BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- =====================================================================
-- SECTION 3: ROLE-BASED ACCESS CONTROL (RBAC) CONFIGURATION
-- =====================================================================
CREATE TABLE IF NOT EXISTS roles (
    role_name VARCHAR(50) PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS permissions (
    permission_key VARCHAR(100) PRIMARY KEY,
    description TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS role_permissions (
    role_name VARCHAR(50) REFERENCES roles(role_name) ON DELETE CASCADE,
    permission_key VARCHAR(100) REFERENCES permissions(permission_key) ON DELETE CASCADE,
    PRIMARY KEY (role_name, permission_key)
);

CREATE TABLE IF NOT EXISTS user_roles (
    username VARCHAR(100) REFERENCES system_users(username) ON DELETE CASCADE,
    role_name VARCHAR(50) REFERENCES roles(role_name) ON DELETE CASCADE,
    PRIMARY KEY (username, role_name)
);

-- =====================================================================
-- SECTION 4: REGULATORY IRB & FDA TRACKING PROTOCOLS
-- =====================================================================
CREATE TABLE IF NOT EXISTS irb_protocols (
    master_protocol_id VARCHAR(50) PRIMARY KEY,
    fda_correspondence_ref VARCHAR(100) NOT NULL UNIQUE,
    reviewing_irb VARCHAR(255) NOT NULL,
    regulatory_framework VARCHAR(100) DEFAULT '21 CFR Parts 50, 56, 312'
);

CREATE TABLE IF NOT EXISTS patient_anonymization_ledger (
    de_identified_code VARCHAR(50) PRIMARY KEY,
    master_protocol_id VARCHAR(50) REFERENCES irb_protocols(master_protocol_id),
    encrypted_emr_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 baseline token ensuring zero patient PHI leakage
    eind_fda_reference VARCHAR(100) NOT NULL,
    assigned_telehealth_md VARCHAR(10) REFERENCES providers(provider_npi),
    site_access_token VARCHAR(50) NOT NULL,
    compliance_verification VARCHAR(50) DEFAULT 'VERIFIED'
);

-- =====================================================================
-- SECTION 5: NATIONAL EPIDEMIOLOGICAL SURVEILLANCE DATA
-- =====================================================================
CREATE TABLE IF NOT EXISTS national_disease_registry (
    registry_case_id VARCHAR(50) PRIMARY KEY,
    confirmed_pathogen VARCHAR(100) NOT NULL,
    reporting_jurisdiction_state CHAR(2) NOT NULL,
    outbreak_cohort_year INT NOT NULL,
    epidemiological_alert_level VARCHAR(50) CHECK (epidemiological_alert_level IN ('BASELINE', 'MONITORED', 'SURGE_WARNING', 'CRITICAL'))
);

-- =====================================================================
-- SECTION 6: PRODUCT LOTS & AUTOMATED BOTANICAL LOGISTICS
-- =====================================================================
CREATE TABLE IF NOT EXISTS product_lots (
    lot_number VARCHAR(50) PRIMARY KEY,
    product_selection VARCHAR(100) NOT NULL,
    molecular_weight_verified BOOLEAN DEFAULT FALSE,
    ph_optimized BOOLEAN DEFAULT FALSE,
    contaminant_screening_status VARCHAR(50) DEFAULT 'PASSED_ND'
);

CREATE TABLE IF NOT EXISTS high_containment_manifests (
    manifest_id VARCHAR(50) PRIMARY KEY,
    isolate_code VARCHAR(50) NOT NULL,
    biological_safety_level VARCHAR(10) CHECK (biological_safety_level IN ('BSL-1', 'BSL-2', 'BSL-3', 'BSL-4')),
    origin_facility VARCHAR(255) NOT NULL,
    target_receiving_facility VARCHAR(255) NOT NULL,
    transit_vehicle_id VARCHAR(50) NOT NULL,
    quarantine_status VARCHAR(50) NOT NULL,
    authorized_signoff_npi VARCHAR(10) REFERENCES providers(provider_npi)
);

CREATE TABLE IF NOT EXISTS telemetry_transit_logs (
    shipment_id VARCHAR(50) PRIMARY KEY,
    lot_number VARCHAR(50) REFERENCES product_lots(lot_number),
    destination_hospital VARCHAR(255) NOT NULL,
    sensors_active BOOLEAN DEFAULT TRUE,
    thermal_status_celsius NUMERIC(4,2) NOT NULL,
    chain_of_custody_signature VARCHAR(255) NOT NULL,
    delivery_status VARCHAR(50) NOT NULL CHECK (delivery_status IN ('IN_TRANSIT', 'PENDING_ARRIVAL', 'DELIVERED_RECONCILED', 'QUARANTINED'))
);

-- =====================================================================
-- SECTION 7: CLINICAL ENCOUNTERS, STABILIZATION & LATENCY TRACKING
-- =====================================================================
CREATE TABLE IF NOT EXISTS patient_clinical_outcomes (
    de_identified_code VARCHAR(50) PRIMARY KEY sa_references REFERENCES patient_anonymization_ledger(de_identified_code) ON DELETE CASCADE,
    registry_case_id VARCHAR(50) REFERENCES national_disease_registry(registry_case_id),
    primary_specialty_track VARCHAR(100) NOT NULL, -- Oncology, Regenerative Medicine, Pathology, Sports Med
    assigned_lot_number VARCHAR(50) REFERENCES product_lots(lot_number),
    baseline_severity_score INT CHECK (baseline_severity_score BETWEEN 1 AND 10),
    post_intervention_score INT CHECK (post_intervention_score BETWEEN 1 AND 10),
    clinical_disposition VARCHAR(50) CHECK (clinical_disposition IN ('RECOVERY_STABLE', 'REHABILITATION', 'ACUTE_TRAUMA_TRANSFER', 'MONITORED_MAINTENANCE')),
    
    -- Specialized Delivery Routing & Critical Kinematics Parameters
    treatment_route_delivery VARCHAR(20) DEFAULT 'PO_ND' CHECK (treatment_route_delivery IN ('PO_ND', 'IV_REGEN_TRAUMA', 'TOPICAL_ENCAP')),
    expected_latency_months INT DEFAULT 6,
    lipid_toxicity_warning_active BOOLEAN DEFAULT FALSE,
    vector_containment_breach BOOLEAN DEFAULT FALSE,
    
    -- Emergency EHR Automated Dispatch Stabilizers
    ehr_contact_stabilization_triggered BOOLEAN DEFAULT FALSE,
    initial_alnayasn_dose_administered BOOLEAN DEFAULT FALSE,
    initial_tsinkx_dose_administered BOOLEAN DEFAULT FALSE
);

-- =====================================================================
-- SECTION 8: ACADEMIC TRAINING & RESIDENCY CREDIT METRICS
-- =====================================================================
CREATE TABLE IF NOT EXISTS resident_rotation_summary (
    rotation_id VARCHAR(50) PRIMARY KEY,
    resident_name VARCHAR(255) NOT NULL,
    affiliated_institution VARCHAR(255) NOT NULL,
    specialty_track VARCHAR(100) NOT NULL,
    completed_encounters INT DEFAULT 0,
    supervising_attending_npi VARCHAR(10) REFERENCES providers(provider_npi),
    total_validated_hours NUMERIC(5,2) DEFAULT 0.00,
    milestone_status VARCHAR(50) CHECK (milestone_status IN ('APPROVED_CREDIT', 'IN_PROGRESS', 'PENDING_REVIEW'))
);

-- =====================================================================
-- SECTION 9: IMMUTABLE AUDIT LOG ENGINE & FIREWALL HOOKS
-- =====================================================================
CREATE TABLE IF NOT EXISTS security_audit_logs (
    audit_id BIGSERIAL PRIMARY KEY,
    username VARCHAR(100) NOT NULL,
    system_role VARCHAR(50),
    request_method VARCHAR(10) NOT NULL,
    endpoint_path VARCHAR(255) NOT NULL,
    sql_action_type VARCHAR(20) NOT NULL,
    client_ip VARCHAR(45),
    lot_number_context VARCHAR(50),
    execution_timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status_code INT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_audit_timestamp ON security_audit_logs(execution_timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_audit_username ON security_audit_logs(username);

-- =====================================================================
-- SECTION 10: REAL-TIME SURVEILLANCE & POLICY ENFORCEMENT VIEWS
-- =====================================================================

-- Safety View A: Automatically flag high-risk clinical latency drift or missed stabilizer dosing loops
CREATE OR REPLACE VIEW v_acute_latency_compliance_breaches AS
SELECT 
    pco.de_identified_code,
    pco.primary_specialty_track,
    pco.treatment_route_delivery,
    pco.expected_latency_months,
    pco.ehr_contact_stabilization_triggered,
    pco.initial_alnayasn_dose_administered,
    pco.initial_tsinkx_dose_administered,
    pco.clinical_disposition
FROM patient_clinical_outcomes pco
WHERE pco.primary_specialty_track = 'Regenerative Medicine'
  AND (pco.treatment_route_delivery = 'PO_ND' 
       OR pco.initial_alnayasn_dose_administered = FALSE 
       OR pco.initial_tsinkx_dose_administered = FALSE);

-- Safety View B: Identify distributed network intrusions grouped by Class C /24 Subnets for edge blocking
CREATE OR REPLACE VIEW v_automated_firewall_blacklist AS
SELECT 
text(set_masklen(client_ip::inet, 24)) AS c_block_subnet_to_ban,\
COUNT(*) AS absolute_violation_count,\
MIN(execution_timestamp) AS first_assault_detected,\
MAX(execution_timestamp) AS last_assault_detected,\
'AUTOMATED_PERIMETER_DROP' AS dynamic_iptables_action_directive\
FROM security_audit_logs\
WHERE status_code IN (401, 403)\
AND execution_timestamp >= NOW() - INTERVAL '48 hours'\
GROUP BY set_masklen(client_ip::inet, 24)\
HAVING COUNT(*) > 10;

-- =====================================================================\
-- SECTION 11: INITIAL VALIDATION SEED DATA MATRIX\
-- =====================================================================

-- Roles Catalog Seed\
INSERT INTO roles (role_name, description) VALUES\
('ATTENDING_PHYSICIAN', 'Full clinical, telemetry oversight, and automated lot quarantine operational authority.'),\
('MEDICAL_STUDENT', 'Read-only access to de-identified cases, tracking maps, and residency rotation logs.')\
ON CONFLICT DO NOTHING;

-- Permissions Catalog Seed\
INSERT INTO permissions (permission_key, description) VALUES\
('read:maps', 'Permission to view geographic vector and transmission maps.'),\
('write:prescriptions', 'Permission to draft and authorize digital prescription manifolds.'),\
('execute:quarantine', 'Permission to manually fire geofencing or lot quarantine triggers.'),\
('read:academic_records', 'Permission to view residency and student milestone evaluations.')\
ON CONFLICT DO NOTHING;

-- Map Role-Permissions Junctions\
INSERT INTO role_permissions (role_name, permission_key) VALUES\
('ATTENDING_PHYSICIAN', 'read:maps'), ('ATTENDING_PHYSICIAN', 'write:prescriptions'),\
('ATTENDING_PHYSICIAN', 'execute:quarantine'), ('ATTENDING_PHYSICIAN', 'read:academic_records'),\
('MEDICAL_STUDENT', 'read:maps'), ('MEDICAL_STUDENT', 'read:academic_records')\
ON CONFLICT DO NOTHING;

-- Seed Admin Profile (Bcrypt hash corresponds to password 'SecureCryptoPass2026')\
INSERT INTO system_users (username, email, full_name, hashed_password, is_disabled)\
VALUES ('vtc_command_admin', 'security@virustc.com', 'Yesler Towers Security Officer', '$2b$12$R9h/bIEU6Y9J6.gqVfLKeObK111uXWkZ3h/oE1KjM66mF8vT2K1L.', FALSE)\
ON CONFLICT DO NOTHING;

INSERT INTO user_roles (username, role_name) VALUES ('vtc_command_admin', 'ATTENDING_PHYSICIAN') ON CONFLICT DO NOTHING;

-- Seed Primary Botanical Compound Matrices\
INSERT INTO product_lots (lot_number, product_selection, molecular_weight_verified, ph_optimized, contaminant_screening_status)\
VALUES\
('VND-1600-01', 'Vendula-1600mg (Lavandula angustifolia)', TRUE, TRUE, 'PASSED_ND'),\
('ECT-02OZ-09', 'Ectogano-2oz (Origanum vulgare)', TRUE, TRUE, 'PASSED_ND'),\
('PFK-240M-03', 'Pefkon-240mg (Pinus pinaster)', TRUE, FALSE, 'PASSED_ND')\
ON CONFLICT DO NOTHING;
