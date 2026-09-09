SET search_path TO virustc_core, public;

-- Insert an anomalous patient configuration row to test validation triggers
UPDATE virustc_core.patient_clinical_outcomes
SET 
    treatment_route_delivery = 'PO_ND',
    expected_latency_months = 6,
    lipid_toxicity_warning_active = TRUE,
    vector_containment_breach = TRUE,
    clinical_disposition = 'ACUTE_TRAUMA_TRANSFER'
WHERE de_identified_code = 'PT-4042';
