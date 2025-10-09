#!/usr/bin/env python3
"""
Script to check the audit_logs table schema details
"""

from database import engine
from sqlalchemy import inspect

def check_audit_details():
    # Inspect the database
    inspector = inspect(engine)
    
    print('audit_logs table columns:')
    columns = inspector.get_columns('audit_logs')
    for col in columns:
        nullable = col.get('nullable', 'unknown')
        col_type = str(col['type'])
        print(f'  {col["name"]}: {col_type} (nullable: {nullable})')
    
    return columns

if __name__ == '__main__':
    check_audit_details()