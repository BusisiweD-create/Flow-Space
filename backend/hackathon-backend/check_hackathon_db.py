#!/usr/bin/env python3
"""
Script to check the hackathon.db database tables
"""

import sys
import os
from sqlalchemy import create_engine, inspect

def check_hackathon_db():
    # Create engine using the correct database path
    BASE_DIR = os.path.dirname(os.path.abspath('.'))
    DATABASE_PATH = os.path.join(BASE_DIR, 'hackathon.db')
    DATABASE_URL = f'sqlite:///{DATABASE_PATH}'
    engine = create_engine(DATABASE_URL)
    
    # Inspect the database
    inspector = inspect(engine)
    
    print('Existing tables in hackathon.db:')
    tables = inspector.get_table_names()
    for table in tables:
        print(f'  {table}')
        
    print(f'\nTotal tables: {len(tables)}')
    
    # Check if sprints table exists
    if 'sprints' in tables:
        print('\nsprints table columns:')
        for column in inspector.get_columns('sprints'):
            print(f'  {column["name"]}: {column["type"]}')
    else:
        print('\nsprints table does not exist')
        
    return tables

if __name__ == '__main__':
    tables = check_hackathon_db()