#!/usr/bin/env python3
"""
Script to check the current sprints table schema and identify missing columns
"""

import sys
import os
from sqlalchemy import create_engine, inspect

# Add the current directory to Python path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from models import Sprint

def check_sprints_schema():
    # Create engine
    database_url = os.getenv('DATABASE_URL', 'sqlite:///./test.db')
    engine = create_engine(database_url)
    
    # Inspect the database
    inspector = inspect(engine)
    
    # Check sprints table columns
    if 'sprints' in inspector.get_table_names():
        print('Current sprints table columns:')
        for column in inspector.get_columns('sprints'):
            print(f'  {column["name"]}: {column["type"]}')
        print()
        
        # Get expected columns from Sprint model
        expected_columns = [col.name for col in Sprint.__table__.columns]
        print('Expected columns from Sprint model:')
        for col in expected_columns:
            print(f'  {col}')
        print()
        
        # Find missing columns
        current_columns = [col['name'] for col in inspector.get_columns('sprints')]
        missing_columns = set(expected_columns) - set(current_columns)
        print('Missing columns:')
        for col in missing_columns:
            print(f'  {col}')
            
        return list(missing_columns)
    else:
        print('sprints table does not exist')
        return []

if __name__ == '__main__':
    missing_columns = check_sprints_schema()
    print(f'\nTotal missing columns: {len(missing_columns)}')