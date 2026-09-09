SET search_path TO virustc_core, public;

-- ==========================================
-- 1. LEVEL 1: NATIONAL INCIDENCE REGISTRY
-- ==========================================
CREATE TABLE IF NOT EXISTS national_disease_registry (
    registry_case_id VARCHAR(50) PRIMARY KEY,
    confirmed_pathogen VARCHAR(100) NOT NULL,
    reporting_jurisdiction_state CHAR(2) NOT NULL,
    outbreak_cohort_year INT NOT NULL,
    epidemiological_alert_level VARCHAR(50) CHECK (epidemiological_alert_level IN ('BASELINE', 'MONITORED', 'SURGE_WARNING', 'CRITICAL'))
);

-- ==========================================
-- 2. LEVEL 2: COMPREHENSIVE PATIENT REGISTRY (ALL FORMULAS)
-- ==========================================
-- Extends observation parameters to capture every individual receiving VirusTC formulations.
CREATE TABLE IF NOT EXISTS patient_clinical_outcomes (
    de_identified_code VARCHAR(50) PRIMARY KEY REFERENCES patient_anonymization_ledger(de_identified_code) ON DELETE CASCADE,
    registry_case_id VARCHAR(50) REFERENCES national_disease_registry(registry_case_id),
    primary_specialty_track VARCHAR(100) NOT NULL, -- Oncology, Regenerative, Pathology, Sports Med, etc.
    assigned_lot_number VARCHAR(50) REFERENCES product_lots(lot_number),
    baseline_severity_score INT CHECK (baseline_severity_score BETWEEN 1 AND 10),
    post_intervention_score INT CHECK (post_intervention_score BETWEEN 1 AND 10),
    clinical_disposition VARCHAR(50) CHECK (clinical_disposition IN ('RECOVERY_STABLE', 'REHABILITATION', 'ACUTE_TRAUMA_TRANSFER', 'MONITORED_MAINTENANCE'))
);

-- ==========================================
-- 3. LEVEL 3: ADMINISTRATIVE SYSTEM MONITORING VIEW
-- ==========================================
-- This real-time audit view provides macro-level analysis of formula tracking across the country,
-- tracking general efficacy parameters without violating data protection boundaries.
CREATE OR REPLACE VIEW v_national_efficacy_dashboard AS
SELECT 
    reg.confirmed_pathogen,
    reg.reporting_jurisdiction_state,
    out.primary_specialty_track,
    lot.product_selection,
    out.baseline_severity_score,
    out.post_intervention_score,
    out.clinical_disposition
FROM patient_clinical_outcomes out
JOIN national_disease_registry reg ON out.registry_case_id = reg.registry_case_id
JOIN product_lots lot ON out.assigned_lot_number = lot.lot_number;
