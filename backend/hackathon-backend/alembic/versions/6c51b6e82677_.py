"""empty message

Revision ID: 6c51b6e82677
Revises: add_missing_deliverable_columns, ce7c48d9cae4
Create Date: 2025-10-07 14:26:21.979196

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '6c51b6e82677'
down_revision: Union[str, None] = ('add_missing_deliverable_columns', 'ce7c48d9cae4')
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    pass


def downgrade() -> None:
    pass
