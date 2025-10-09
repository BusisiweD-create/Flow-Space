"""Add missing deliverable columns

Revision ID: add_missing_deliverable_columns
Revises: manual_add_definition_of_done
Create Date: 2025-10-03 23:45:00.000000

"""

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects import sqlite

# revision identifiers, used by Alembic.
revision = 'add_missing_deliverable_columns'
down_revision = 'manual_add_definition_of_done'
branch_labels = None
depends_on = None

def upgrade():
    # Add all missing columns to deliverables table
    op.add_column('deliverables', sa.Column('evidence_links', sa.JSON(), nullable=True))
    op.add_column('deliverables', sa.Column('demo_link', sa.String(length=500), nullable=True))
    op.add_column('deliverables', sa.Column('repo_link', sa.String(length=500), nullable=True))
    op.add_column('deliverables', sa.Column('test_summary_link', sa.String(length=500), nullable=True))
    op.add_column('deliverables', sa.Column('user_guide_link', sa.String(length=500), nullable=True))
    op.add_column('deliverables', sa.Column('test_pass_rate', sa.Integer(), nullable=True))
    op.add_column('deliverables', sa.Column('code_coverage', sa.Integer(), nullable=True))
    op.add_column('deliverables', sa.Column('escaped_defects', sa.Integer(), nullable=True))
    op.add_column('deliverables', sa.Column('defect_severity_mix', sa.JSON(), nullable=True))
    op.add_column('deliverables', sa.Column('submitted_at', sa.DateTime(timezone=True), nullable=True))
    op.add_column('deliverables', sa.Column('approved_at', sa.DateTime(timezone=True), nullable=True))

def downgrade():
    # Remove all the columns we added
    op.drop_column('deliverables', 'evidence_links')
    op.drop_column('deliverables', 'demo_link')
    op.drop_column('deliverables', 'repo_link')
    op.drop_column('deliverables', 'test_summary_link')
    op.drop_column('deliverables', 'user_guide_link')
    op.drop_column('deliverables', 'test_pass_rate')
    op.drop_column('deliverables', 'code_coverage')
    op.drop_column('deliverables', 'escaped_defects')
    op.drop_column('deliverables', 'defect_severity_mix')
    op.drop_column('deliverables', 'submitted_at')
    op.drop_column('deliverables', 'approved_at')