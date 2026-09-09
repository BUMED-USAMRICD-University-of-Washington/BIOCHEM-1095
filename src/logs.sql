-- CREATE SCHEMA FOR VIRUSTC COMPLIANCE AND LOGISTICS PIPELINE
CREATE SCHEMA IF NOT EXISTS virustc_core;
SET search_path TO virustc_core, public;

-- ==========================================
-- 1. CLINICAL PROVIDER AND TELEHEALTH GATING
-- ==========================================

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

-- ==========================================
-- 2. PATIENT ANONYMIZATION AND IRB PROTOCOLS
-- ==========================================

CREATE TABLE IF NOT EXISTS irb_protocols (
    master_protocol_id VARCHAR(50) PRIMARY KEY,
    fda_correspondence_ref VARCHAR(100) NOT NULL UNIQUE,
    reviewing_irb VARCHAR(255) NOT NULL,
    regulatory_framework VARCHAR(100) DEFAULT '21 CFR Parts 50, 56, 312'
);

CREATE TABLE IF NOT EXISTS patient_anonymization_ledger (
    de_identified_code VARCHAR(50) PRIMARY KEY,
    master_protocol_id VARCHAR(50) REFERENCES irb_protocols(master_protocol_id),
    encrypted_emr_hash VARCHAR(64) NOT NULL UNIQUE, -- SHA-256 Hash to prevent PHI storage
    eind_fda_reference VARCHAR(100) NOT NULL,
    assigned_telehealth_md VARCHAR(10) REFERENCES providers(provider_npi),
    site_access_token VARCHAR(50) NOT NULL,
    compliance_verification VARCHAR(50) DEFAULT 'VERIFIED'
);

-- ==========================================
-- 3. LOGISTICS, QUARANTINE AND COLD-CHAIN
-- ==========================================

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

-- ==========================================
-- 4. ACADEMIC AND RESIDENCY MILESTONES
-- ==========================================

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

-- ==========================================
-- 5. RELATIONAL CROSS-STATE CROSS-CHECK VIEW
-- ==========================================
-- This database safety view automatically flags instances where an encounter was assigned 
-- but the provider's licensed states do not cover the patient's state routing matrix.

CREATE OR REPLACE VIEW v_telehealth_compliance_audit AS
SELECT 
    p.de_identified_code,
    p.master_protocol_id,
    prov.provider_name,
    prov.credentialing_status,
    p.compliance_verification
FROM patient_anonymization_ledger p
JOIN providers prov ON p.assigned_telehealth_md = prov.provider_npi;
