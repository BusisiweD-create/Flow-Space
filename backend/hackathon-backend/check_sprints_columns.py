from sqlalchemy import create_engine, inspect
import os

# Create engine using the correct database path
BASE_DIR = os.path.dirname(os.path.abspath('.'))
DATABASE_PATH = os.path.join(BASE_DIR, 'hackathon.db')
DATABASE_URL = f'sqlite:///{DATABASE_PATH}'
engine = create_engine(DATABASE_URL)

# Inspect the database
inspector = inspect(engine)

# Check sprints table columns
if 'sprints' in inspector.get_table_names():
    print('Current sprints table columns:')
    for column in inspector.get_columns('sprints'):
        print(f'  {column["name"]}: {column["type"]}')
else:
    print('sprints table does not exist')