"""
Alembic migration module to introduce acute trauma latency and toxicity tracking flags.
Revision ID: 2026_09_09_latency_flags_migration
Revises: 2026_09_09_rbac_migration
"""
from alembic import op
import sqlalchemy as sa

# Revision identifiers used by Alembic engine
revision = '2026_09_09_latency_flags_migration'
down_revision = '2026_09_09_rbac_migration'
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. Extend the Patient Clinical Outcomes table with specialized latency, delivery, and containment flags
    op.add_column(
        'patient_clinical_outcomes',
        sa.Column('treatment_route_delivery', sa.String(length=20), server_default='PO_ND', nullable=False),
        schema='virustc_core'
    )
    op.add_column(
        'patient_clinical_outcomes',
        sa.Column('expected_latency_months', sa.Integer(), server_default='6', nullable=False),
        schema='virustc_core'
    )
    op.add_column(
        'patient_clinical_outcomes',
        sa.Column('lipid_toxicity_warning_active', sa.Boolean(), server_default='false', nullable=False),
        schema='virustc_core'
    )
    op.add_column(
        'patient_clinical_outcomes',
        sa.Column('vector_containment_breach', sa.Boolean(), server_default='false', nullable=False),
        schema='virustc_core'
    )

    # 2. Apply a Check Constraint to the treatment route delivery configurations to validate entry values
    op.create_check_constraint(
        'ck_treatment_route_delivery',
        table_name='patient_clinical_outcomes',
        condition="treatment_route_delivery IN ('PO_ND', 'IV_REGEN_TRAUMA', 'TOPICAL_ENCAP')",
        schema='virustc_core'
    )

    # 3. Create the Real-Time Safety View to automatically flag high-risk clinical latency drift
    op.execute("""
        CREATE OR REPLACE VIEW virustc_core.v_acute_latency_compliance_breaches AS
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
    """)

def downgrade() -> None:
    # 1. Tear down the Real-Time Safety View
    op.execute("DROP VIEW IF EXISTS virustc_core.v_acute_latency_compliance_breaches;")

    # 2. Drop the Check Constraint
    op.drop_constraint('ck_treatment_route_delivery', table_name='patient_clinical_outcomes', schema='virustc_core')

    # 3. Remove the extended data columns from the target tracking table layout
    op.drop_column('patient_clinical_outcomes', 'vector_containment_breach', schema='virustc_core')
    op.drop_column('patient_clinical_outcomes', 'lipid_toxicity_warning_active', schema='virustc_core')
    op.drop_column('patient_clinical_outcomes', 'expected_latency_months', schema='virustc_core')
    op.drop_column('patient_clinical_outcomes', 'treatment_route_delivery', schema='virustc_core')
