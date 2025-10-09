"""
Comprehensive database schema fix script
Compares SQLAlchemy models with actual database tables and adds missing columns
"""

import sqlite3
import os
from sqlalchemy import create_engine, inspect
from sqlalchemy.orm import sessionmaker
from database import DATABASE_URL, engine
from models import Base, Deliverable, Sprint, Signoff, AuditLog, User, UserProfile, RefreshToken, UserSettings

def get_model_columns(model_class):
    """Get all columns from a SQLAlchemy model"""
    columns = {}
    for column in model_class.__table__.columns:
        # Map SQLAlchemy types to SQLite types
        col_type = str(column.type)
        if 'INTEGER' in col_type.upper():
            sqlite_type = 'INTEGER'
        elif 'VARCHAR' in col_type.upper() or 'STRING' in col_type.upper():
            sqlite_type = 'VARCHAR(255)' if 'VARCHAR' in col_type.upper() else 'TEXT'
        elif 'TEXT' in col_type.upper():
            sqlite_type = 'TEXT'
        elif 'DATETIME' in col_type.upper():
            sqlite_type = 'DATETIME'
        elif 'BOOLEAN' in col_type.upper():
            sqlite_type = 'BOOLEAN'
        elif 'JSON' in col_type.upper():
            sqlite_type = 'TEXT'  # JSON stored as TEXT in SQLite
        elif 'DATE' in col_type.upper():
            sqlite_type = 'DATE'
        else:
            sqlite_type = 'TEXT'  # Default fallback
            
        columns[column.name] = sqlite_type
    return columns

def get_database_columns(table_name):
    """Get all columns from a database table"""
    conn = sqlite3.connect("hackathon.db")
    cursor = conn.cursor()
    
    cursor.execute(f"PRAGMA table_info({table_name})")
    columns = {}
    for row in cursor.fetchall():
        columns[row[1]] = row[2]  # name: type
    
    conn.close()
    return columns

def fix_table_schema(table_name, model_class):
    """Fix schema for a specific table"""
    print(f"\n=== Fixing {table_name} table ===")
    
    # Get expected columns from model
    model_columns = get_model_columns(model_class)
    print(f"Model expects {len(model_columns)} columns")
    
    # Get actual columns from database
    try:
        db_columns = get_database_columns(table_name)
        print(f"Database has {len(db_columns)} columns")
    except Exception as e:
        print(f"Error reading {table_name} table: {e}")
        return False
    
    # Find missing columns
    missing_columns = {}
    for col_name, col_type in model_columns.items():
        if col_name not in db_columns:
            missing_columns[col_name] = col_type
    
    if not missing_columns:
        print(f"✓ {table_name} table schema is up to date")
        return True
    
    print(f"Missing columns in {table_name}: {list(missing_columns.keys())}")
    
    # Add missing columns
    conn = sqlite3.connect("hackathon.db")
    cursor = conn.cursor()
    
    added_columns = []
    for col_name, col_type in missing_columns.items():
        try:
            sql = f"ALTER TABLE {table_name} ADD COLUMN {col_name} {col_type}"
            print(f"Adding: {sql}")
            cursor.execute(sql)
            added_columns.append(col_name)
            print(f"✓ Added {col_name}")
        except sqlite3.OperationalError as e:
            if "duplicate column name" in str(e):
                print(f"- Column {col_name} already exists")
            else:
                print(f"✗ Error adding {col_name}: {e}")
    
    conn.commit()
    conn.close()
    
    print(f"Successfully added {len(added_columns)} columns to {table_name}")
    return len(added_columns) > 0

def comprehensive_schema_fix():
    """Fix all table schemas"""
    print("Starting comprehensive database schema fix...")
    
    # Check database file
    if not os.path.exists("hackathon.db"):
        print("Database file hackathon.db not found!")
        return False
    
    # Define all models to check
    models_to_check = [
        ("deliverables", Deliverable),
        ("sprints", Sprint),
        ("signoffs", Signoff),
        ("audit_logs", AuditLog),
        ("users", User),
        ("user_profiles", UserProfile),
        ("refresh_tokens", RefreshToken),
        ("user_settings", UserSettings),
    ]
    
    total_changes = 0
    
    for table_name, model_class in models_to_check:
        try:
            changes = fix_table_schema(table_name, model_class)
            if changes:
                total_changes += 1
        except Exception as e:
            print(f"Error fixing {table_name}: {e}")
    
    print(f"\n=== Summary ===")
    print(f"Fixed {total_changes} tables")
    
    # Verify critical tables
    print(f"\n=== Verification ===")
    critical_tables = ["sprints", "signoffs", "deliverables"]
    
    for table_name in critical_tables:
        try:
            conn = sqlite3.connect("hackathon.db")
            cursor = conn.cursor()
            
            # Test key columns
            if table_name == "sprints":
                test_columns = ["planned_points", "committed_points", "completed_points"]
            elif table_name == "signoffs":
                test_columns = ["entity_type", "entity_id", "decision"]
            elif table_name == "deliverables":
                test_columns = ["definition_of_done", "priority", "status"]
            
            for col in test_columns:
                try:
                    cursor.execute(f"SELECT {col} FROM {table_name} LIMIT 1")
                    print(f"✓ {table_name}.{col} is accessible")
                except sqlite3.OperationalError as e:
                    print(f"✗ {table_name}.{col} error: {e}")
            
            conn.close()
            
        except Exception as e:
            print(f"Error verifying {table_name}: {e}")
    
    print("\nSchema fix completed!")
    return True

if __name__ == "__main__":
    comprehensive_schema_fix()