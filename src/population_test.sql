SET search_path TO virustc_core, public;

-- =====================================================================
-- SEED NATIONAL DISEASE BURDEN STATISTICS (LEVEL 1 DATA)
-- =====================================================================
INSERT INTO national_disease_registry (registry_case_id, confirmed_pathogen, reporting_jurisdiction_state, outbreak_cohort_year, epidemiological_alert_level)
VALUES 
('NAT-2026-DNG-088', 'Dengue Virus Variant', 'WA', 2026, 'MONITORED'),
('NAT-2026-EBO-112', 'Ebola Sudan Phenotype', 'CA', 2026, 'CRITICAL'),
('NAT-2026-MAL-401', 'Unstable Oncological Co-infection', 'NY', 2026, 'BASELINE');

-- =====================================================================
-- SEED CLINICAL INTERVENTION METRICS Across ALL SPECIALTIES (LEVEL 2 DATA)
-- =====================================================================
INSERT INTO patient_clinical_outcomes (de_identified_code, registry_case_id, primary_specialty_track, assigned_lot_number, baseline_severity_score, post_intervention_score, clinical_disposition)
VALUES 
-- Naturopathic Oncology Patient tracked under Dengue exposure protocols
('PT-9921', 'NAT-2026-DNG-088', 'Naturopathic Oncology', 'VND-1600-01', 7, 2, 'RECOVERY_STABLE'),

-- Remote Trauma Patient routing directly via the Trauma/Regenerative framework
('PT-4042', 'NAT-2026-EBO-112', 'Regenerative Medicine', 'ECT-02OZ-09', 9, 4, 'ACUTE_TRAUMA_TRANSFER'),

-- Integrative Medicine Patient tracked through state monitoring networks
('PT-1150', 'NAT-2026-MAL-401', 'Integrative Medicine', 'PFK-240M-03', 4, 3, 'MONITORED_MAINTENANCE');
