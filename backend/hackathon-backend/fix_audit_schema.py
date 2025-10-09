#!/usr/bin/env python3
"""
Script to fix audit_logs table schema inconsistencies.
This script will:
1. Drop the unnecessary 'user' column if it exists
2. Drop the unnecessary 'timestamp' column if it exists  
3. Drop the unnecessary 'details' column if it exists
4. Ensure all required columns are present
"""

import os
import sys
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

def fix_audit_schema():
    # Use the actual database URL from environment
    DATABASE_URL = os.getenv('DATABASE_URL', 'sqlite:///./hackathon.db')
    engine = create_engine(DATABASE_URL)
    
    print(f"Connecting to database: {DATABASE_URL}")
    
    # Check current schema
    with engine.connect() as conn:
        # Check if unnecessary columns exist
        result = conn.execute(text("""
            PRAGMA table_info(audit_logs);
        """))
        
        columns = [row[1] for row in result]
        print(f"Current columns in audit_logs table: {columns}")
        
        # Drop unnecessary columns if they exist
        if 'user' in columns:
            print("Dropping 'user' column...")
            conn.execute(text("ALTER TABLE audit_logs DROP COLUMN user"))
            print("✓ Dropped 'user' column")
        
        if 'timestamp' in columns:
            print("Dropping 'timestamp' column...")
            conn.execute(text("ALTER TABLE audit_logs DROP COLUMN timestamp"))
            print("✓ Dropped 'timestamp' column")
            
        if 'details' in columns:
            print("Dropping 'details' column...")
            conn.execute(text("ALTER TABLE audit_logs DROP COLUMN details"))
            print("✓ Dropped 'details' column")
        
        # Commit changes
        conn.commit()
        
        # Verify final schema
        result = conn.execute(text("""
            PRAGMA table_info(audit_logs);
        """))
        
        final_columns = [row[1] for row in result]
        print(f"Final columns in audit_logs table: {final_columns}")
        
        # Check if all required columns are present
        required_columns = [
            'id', 'user_id', 'user_email', 'user_role', 'session_id', 'ip_address',
            'user_agent', 'action', 'action_category', 'entity_type', 'entity_id',
            'entity_name', 'old_values', 'new_values', 'changed_fields', 'request_id',
            'endpoint', 'http_method', 'status_code', 'created_at'
        ]
        
        missing_columns = [col for col in required_columns if col not in final_columns]
        
        if missing_columns:
            print(f"Warning: Missing required columns: {missing_columns}")
        else:
            print("✓ All required columns are present")
            
        print("Schema fix completed successfully!")

if __name__ == "__main__":
    fix_audit_schema()