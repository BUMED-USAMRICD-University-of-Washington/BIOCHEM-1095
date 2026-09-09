SET search_path TO virustc_core, public;

-- =====================================================================
-- 1. POPULATE INITIAL RESEARCH PROTOCOLS (IRB & FDA KEYS)
-- =====================================================================
INSERT INTO irb_protocols (master_protocol_id, fda_correspondence_ref, reviewing_irb, regulatory_framework)
VALUES 
('IRB-VTC-2026-01', 'IND-168224-EAP', 'University of Washington IRB', '21 CFR Parts 50, 56, 312'),
('IRB-VTC-2026-02', 'IND-155310-EAP', 'University of Washington IRB', '21 CFR Parts 50, 56, 312'),
('IRB-VTC-2026-03', 'IND-199421-EAP', 'USAMRICD Research Oversight Board', '21 CFR Parts 50, 56, 312');

-- =====================================================================
-- 2. POPULATE INITIAL PROVIDERS (ATTENDING CLINICIANS)
-- =====================================================================
INSERT INTO providers (provider_npi, provider_name, home_state, compact_license_active, dea_registration_status, credentialing_status)
VALUES 
('1093882711', 'Dr. Correo Hofstad', 'WA', TRUE, 'Active_Schedule_II-V', 'APPROVED'),
('1445210928', 'Dr. Aris Consult_A', 'CA', TRUE, 'Active_Schedule_IV-V', 'APPROVED'),
('1851229304', 'Dr. Elena Consult_B', 'NY', FALSE, 'Limited_Consultative', 'PENDING_RENEWAL');

-- =====================================================================
-- 3. POPULATE MULTI-STATE LICENSE JURISDICTIONS
-- =====================================================================
INSERT INTO provider_licensed_states (provider_npi, licensed_state, expiration_date)
VALUES 
('1093882711', 'WA', '2027-11-15'),
('1093882711', 'CA', '2027-11-15'),
('1093882711', 'OR', '2027-11-15'),
('1445210928', 'CA', '2027-04-20'),
('1445210928', 'AZ', '2027-04-20'),
('1851229304', 'NY', '2026-12-31'),
('1851229304', 'NJ', '2026-12-31');

-- =====================================================================
-- 4. POPULATE DE-IDENTIFIED PATIENT LEDGERS (CRYPTOGRAPHIC HASHES)
-- =====================================================================
INSERT INTO patient_anonymization_ledger (de_identified_code, master_protocol_id, encrypted_emr_hash, eind_fda_reference, assigned_telehealth_md, site_access_token, compliance_verification)
VALUES 
('PT-9921', 'IRB-VTC-2026-01', 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855', 'EIND-2026-09A', '1093882711', 'TOK-SEA-001', 'VERIFIED'),
('PT-4042', 'IRB-VTC-2026-01', '87428fc522803d31065e7bce3cf03fe475096631e5e07bbd7a0fde60c4cf25c7', 'EIND-2026-14B', '1445210928', 'TOK-SFO-004', 'VERIFIED'),
('PT-1150', 'IRB-VTC-2026-02', '5feceb66ffc86f38d952786c6d696c79c2dbc239dd4e91b46729d73a27fb57e9', 'EIND-2026-77X', '1851229304', 'TOK-NYC-012', 'VERIFIED');

-- =====================================================================
-- 5. POPULATE PRODUCT LOTS USING BOTANICAL / PHYTOCHEMICAL FORMULAS
-- =====================================================================
INSERT INTO product_lots (lot_number, product_selection, molecular_weight_verified, ph_optimized, contaminant_screening_status)
VALUES 
('VND-1600-01', 'Vendula-1600mg (Lavandula angustifolia)', TRUE, TRUE, 'PASSED_ND'),
('ECT-02OZ-09', 'Ectogano-2oz (Origanum vulgare)', TRUE, TRUE, 'PASSED_ND'),
('PFK-240M-03', 'Pefkon-240mg (Pinus pinaster)', TRUE, FALSE, 'PASSED_ND'),
('NMX-1500-12', 'NiMax-1500mg (Azadirachtin D Complex)', FALSE, FALSE, 'QUARANTINED_RETEST');

-- =====================================================================
-- 6. POPULATE HIGH-CONTAINMENT BIOLOGICAL TRANSIT MANIFESTS
-- =====================================================================
INSERT INTO high_containment_manifests (manifest_id, isolate_code, biological_safety_level, origin_facility, target_receiving_facility, transit_vehicle_id, quarantine_status, authorized_signoff_npi)
VALUES 
('QCM-2026-001', 'VIR-DNG-02 (Dengue)', 'BSL-3', 'Yesler Towers Command Center', 'UW Harborview Trauma Center', 'AMB-CCT-09', 'RELEASED_TO_TRAUMA', '1093882711'),
('QCM-2026-002', 'VIR-EBO-05 (Ebola Sudan)', 'BSL-4', 'Field Deployment Unit Alpha', 'USAMRICD Isolation Wing', 'MIL-C130-44', 'ACTIVE_QUARANTINE', '1445210928'),
('QCM-2026-003', 'VIR-LAS-07 (Lassa Fever)', 'BSL-3', 'Regional Isolation Clinic East', 'UW Harborview Trauma Center', 'AMB-CCT-12', 'PENDING_SCREENING', '1851229304');

-- =====================================================================
-- 7. POPULATE TELEMETRY LOGS (REAL-TIME COLD-CHAIN TELEMETRY VALUES)
-- =====================================================================
INSERT INTO telemetry_transit_logs (shipment_id, lot_number, destination_hospital, sensors_active, thermal_status_celsius, chain_of_custody_signature, delivery_status)
VALUES 
('SH-99201', 'VND-1600-01', 'UW Harborview Medical Center', TRUE, -2.40, 'Signed_M_Hofstad_MD', 'DELIVERED_RECONCILED'),
('SH-99202', 'ECT-02OZ-09', 'USAMRICD Clinical Core', TRUE, 4.10, 'Signed_A_Consult_PharmD', 'DELIVERED_RECONCILED'),
('SH-99203', 'PFK-240M-03', 'Harborview Regenerative Suite', TRUE, -1.80, 'Pending_Dock_A_Officer', 'IN_TRANSIT');

-- =====================================================================
-- 8. POPULATE ACADEMIC ROTATIONS (MEDICAL STUDENT AND RESIDENCY RECORDS)
-- =====================================================================
INSERT INTO resident_rotation_summary (rotation_id, resident_name, affiliated_institution, specialty_track, completed_encounters, supervising_attending_npi, total_validated_hours, milestone_status)
VALUES 
('RES-2026-01', 'Dr. Alex Vance', 'University of Washington', 'Naturopathic Oncology', 45, '1093882711', 80.00, 'APPROVED_CREDIT'),
('RES-2026-02', 'Dr. Morgan Chen', 'KU School of Medicine', 'Pathology Diagnostics', 32, '1093882711', 60.00, 'IN_PROGRESS'),
('RES-2026-03', 'Dr. Kiran Patel', 'Seattle Bio-Med PostDoc Hub', 'Regenerative Transport Systems', 12, '1445210928', 30.00, 'PENDING_REVIEW');
