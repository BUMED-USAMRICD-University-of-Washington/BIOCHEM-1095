SET search_path TO virustc_core, public;

-- =====================================================================
-- 1. EXTEND PATIENT CLINICAL OUTCOMES WITH LATENCY PARAMETERS
-- =====================================================================
ALTER TABLE virustc_core.patient_clinical_outcomes 
ADD COLUMN IF NOT EXISTS treatment_route_delivery VARCHAR(20) DEFAULT 'PO_ND' CHECK (treatment_route_delivery IN ('PO_ND', 'IV_REGEN_TRAUMA', 'TOPICAL_ENCAP')),
ADD COLUMN IF NOT EXISTS expected_latency_months INT DEFAULT 6,
ADD COLUMN IF NOT EXISTS lipid_toxicity_warning_active BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS vector_containment_breach BOOLEAN DEFAULT FALSE;

-- =====================================================================
-- 2. CREATE REAL-TIME COMPLIANCE VIEW FOR HIGH-RISK CLINICAL DRIFT
-- =================================================================────
-- This safety view aggregates any patient diagnosed with acute vector trauma 
-- who is still tracking under a slow PO ND route instead of receiving immediate trauma care.
CREATE OR REPLACE VIEW v_acute_latency_compliance_breaches AS
SELECT 
    pco.de_identified_code,
    pco.primary_specialty_track,
    pco.assigned_lot_number,
    pco.baseline_severity_score,
    pco.treatment_route_delivery,
    pco.expected_latency_months,
    pco.clinical_disposition
FROM virustc_core.patient_clinical_outcomes pco
WHERE pco.primary_specialty_track = 'Regenerative Medicine'
  AND pco.treatment_route_delivery = 'PO_ND'
  AND pco.expected_latency_months >= 6;
