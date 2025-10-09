#!/usr/bin/env python3
"""
Script to check the audit_logs table schema
"""

from database import engine
from sqlalchemy import inspect

def check_audit_schema():
    # Inspect the database
    inspector = inspect(engine)
    
    print('Existing tables:')
    tables = inspector.get_table_names()
    for table in tables:
        print(f'  {table}')
    
    # Check if audit_logs table exists
    if 'audit_logs' in tables:
        print('\naudit_logs table columns:')
        for column in inspector.get_columns('audit_logs'):
            print(f'  {column["name"]}: {column["type"]}')
    else:
        print('\naudit_logs table does not exist')
        
    return tables

if __name__ == '__main__':
    check_audit_schema()