"""
Alembic migration module to introduce RBAC permissions infrastructure.
Revision ID: 2026_09_09_rbac_migration
Revises: previous_revision_id_placeholder
"""
from alembic import op
import sqlalchemy as sa

# Revision identifiers used by Alembic engine
revision = '2026_09_09_rbac_migration'
down_revision = None  # Modify based on your current live migration history tree branch
branch_labels = None
depends_on = None

def upgrade() -> None:
    # 1. Instantiate the System Roles tracking matrix
    op.create_table(
        'roles',
        sa.Column('role_name', sa.String(length=50), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint('role_name'),
        schema='virustc_core'
    )

    # 2. Instantiate the Permissions configuration catalog
    op.create_table(
        'permissions',
        sa.Column('permission_key', sa.String(length=100), nullable=False),
        sa.Column('description', sa.Text(), nullable=False),
        sa.PrimaryKeyConstraint('permission_key'),
        schema='virustc_core'
    )

    # 3. Connect roles to specific system execution permissions
    op.create_table(
        'role_permissions',
        sa.Column('role_name', sa.String(length=50), nullable=False),
        sa.Column('permission_key', sa.String(length=100), nullable=False),
        sa.ForeignKeyConstraint(['permission_key'], ['virustc_core.permissions.permission_key'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['role_name'], ['virustc_core.roles.role_name'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('role_name', 'permission_key'),
        schema='virustc_core'
    )

    # 4. Map active users to their respective access controls
    op.create_table(
        'user_roles',
        sa.Column('username', sa.String(length=100), nullable=False),
        sa.Column('role_name', sa.String(length=50), nullable=False),
        sa.ForeignKeyConstraint(['role_name'], ['virustc_core.roles.role_name'], ondelete='CASCADE'),
        sa.ForeignKeyConstraint(['username'], ['virustc_core.system_users.username'], ondelete='CASCADE'),
        sa.PrimaryKeyConstraint('username', 'role_name'),
        schema='virustc_core'
    )

def downgrade() -> None:
    # Drop relational elements sequentially to preserve internal constraint chains cleanly
    op.drop_table('user_roles', schema='virustc_core')
    op.drop_table('role_permissions', schema='virustc_core')
    op.drop_table('permissions', schema='virustc_core')
    op.drop_table('roles', schema='virustc_core')
