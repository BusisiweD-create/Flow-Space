# Alembic Database Migration Commands

This document provides a comprehensive guide to using Alembic for database migrations in the Hackathon Backend project.

## Setup and Initialization

### Initialize Alembic (already done)
```bash
python -m alembic init alembic
```

### Configure Alembic
Edit `alembic.ini` to set the database connection string:
```ini
sqlalchemy.url = sqlite:///./hackathon.db
```

Edit `alembic/env.py` to import your models and set `target_metadata`:
```python
from models import Base
target_metadata = Base.metadata
```

## Basic Migration Commands

### Create a New Migration
```bash
# Auto-generate migration based on model changes
python -m alembic revision --autogenerate -m "migration_description"

# Create empty migration (manual changes)
python -m alembic revision -m "migration_description"
```

### Apply Migrations
```bash
# Apply all pending migrations
python -m alembic upgrade head

# Apply to specific revision
python -m alembic upgrade <revision_id>

# Apply one step at a time
python -m alembic upgrade +1
```

### Rollback Migrations
```bash
# Rollback one migration
python -m alembic downgrade -1

# Rollback to specific revision
python -m alembic downgrade <revision_id>

# Rollback all migrations
python -m alembic downgrade base
```

### Check Migration Status
```bash
# Show current migration status
python -m alembic current

# Show migration history
python -m alembic history

# Show specific revision details
python -m alembic show <revision_id>
```

## Advanced Commands

### Stamp Database (Mark as Current)
```bash
# Mark database as being at specific revision without running migrations
python -m alembic stamp <revision_id>

# Mark as latest revision
python -m alembic stamp head
```

### Generate SQL Scripts (Dry Run)
```bash
# Generate SQL for migration without executing
python -m alembic upgrade head --sql

# Generate SQL for specific revision range
python -m alembic upgrade <revision1>:<revision2> --sql
```

### Edit Existing Migration
```bash
# Edit the most recent migration
python -m alembic edit head

# Edit specific revision
python -m alembic edit <revision_id>
```

## Common Workflows

### Development Workflow
1. Make changes to your SQLAlchemy models
2. Generate migration: `python -m alembic revision --autogenerate -m "description"`
3. Review the generated migration file
4. Apply migration: `python -m alembic upgrade head`
5. Test your application

### Production Deployment
1. Generate migration scripts in development
2. Test migrations thoroughly
3. Deploy application code
4. Run migrations: `python -m alembic upgrade head`
5. Verify application functionality

### Rollback Procedure
1. Identify issue with current migration
2. Rollback: `python -m alembic downgrade -1`
3. Fix the migration or model issue
4. Create new migration: `python -m alembic revision --autogenerate -m "fix_description"`
5. Apply fixed migration: `python -m alembic upgrade head`

## Troubleshooting

### Common Issues

**Migration conflicts**: If you encounter conflicts, you may need to:
- Manually resolve merge conflicts in migration files
- Use `alembic merge` to combine branches

**Database out of sync**: If the database doesn't match expected state:
- Use `alembic stamp` to mark current state
- Create manual migration to sync changes

**SQLite limitations**: Remember that SQLite has limited ALTER TABLE support:
- Complex schema changes may require manual migration steps
- Consider using batch operations for SQLite

### Environment Setup
Ensure your environment variables are set correctly:
```bash
# For different environments
export DATABASE_URL=sqlite:///./hackathon.db  # Development
export DATABASE_URL=postgresql://user:pass@localhost/db  # Production
```

## Best Practices

1. **Always review auto-generated migrations** before applying them
2. **Test migrations** in a staging environment before production
3. **Keep migration files** in version control
4. **Use descriptive migration messages** for better tracking
5. **Backup your database** before running migrations
6. **Document complex migrations** with comments in the migration files

## File Structure
```
alembic/
├── env.py          # Alembic environment configuration
├── README          # Basic documentation
├── script.py.mako # Migration template
└── versions/       # Migration files
    ├── 123abc..._initial_migration.py
    └── 456def..._add_new_feature.py
```

## Migration File Template
Migration files follow this structure:
```python
"""migration description

Revision ID: 123abc456def
Revises: previous_revision_id
Create Date: 2024-01-01 12:00:00
"""

from alembic import op
import sqlalchemy as sa

# revision identifiers, used by Alembic
revision = '123abc456def'
down_revision = 'previous_revision_id'
branch_labels = None
depends_on = None

def upgrade():
    # Migration operations for upgrade
    op.create_table(...)
    op.add_column(...)

def downgrade():
    # Migration operations for downgrade (rollback)
    op.drop_table(...)
    op.drop_column(...)
```