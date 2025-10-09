"""manual_add_definition_of_done

Manual migration to add definition_of_done column to deliverables table
SQLite doesn't support complex ALTER operations, so we use a simple approach

Revision ID: manual_add_definition_of_done
Revises: f7a2740971b9
Create Date: 2025-10-03 23:45:00.000000
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic.
revision = 'manual_add_definition_of_done'
down_revision = 'f7a2740971b9'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Add the missing definition_of_done column to deliverables table
    op.add_column('deliverables', sa.Column('definition_of_done', sa.Text(), nullable=True))
    
    # Add other essential columns that are causing the 500 error
    op.add_column('deliverables', sa.Column('priority', sa.String(length=50), nullable=True))
    op.add_column('deliverables', sa.Column('due_date', sa.DateTime(timezone=True), nullable=True))
    op.add_column('deliverables', sa.Column('created_by', sa.String(length=255), nullable=True))
    op.add_column('deliverables', sa.Column('assigned_to', sa.String(length=255), nullable=True))


def downgrade() -> None:
    # Remove the columns we added
    op.drop_column('deliverables', 'definition_of_done')
    op.drop_column('deliverables', 'priority')
    op.drop_column('deliverables', 'due_date')
    op.drop_column('deliverables', 'created_by')
    op.drop_column('deliverables', 'assigned_to')