#!/usr/bin/env python3
"""
Script to check all tables in the database
"""

import sys
import os
from sqlalchemy import create_engine, inspect

def check_all_tables():
    # Create engine
    database_url = os.getenv('DATABASE_URL', 'sqlite:///./test.db')
    engine = create_engine(database_url)
    
    # Inspect the database
    inspector = inspect(engine)
    
    print('Existing tables:')
    tables = inspector.get_table_names()
    for table in tables:
        print(f'  {table}')
    
    # Check if sprints table exists
    if 'sprints' in tables:
        print('\nsprints table columns:')
        for column in inspector.get_columns('sprints'):
            print(f'  {column["name"]}: {column["type"]}')
    else:
        print('\nsprints table does not exist')
        
    return tables

if __name__ == '__main__':
    tables = check_all_tables()
    print(f'\nTotal tables: {len(tables)}')