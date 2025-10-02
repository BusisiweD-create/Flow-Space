#!/usr/bin/env python3
"""
Script to check database schema and data persistence
"""

import sqlite3
import os

def check_database():
    """Check database schema and data"""
    db_path = "hackathon.db"
    
    if not os.path.exists(db_path):
        print(f"❌ Database file {db_path} does not exist")
        return
    
    print(f"✅ Database file {db_path} exists")
    
    try:
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Check tables
        cursor.execute("SELECT name FROM sqlite_master WHERE type='table'")
        tables = cursor.fetchall()
        print(f"\n📊 Tables in database:")
        for table in tables:
            print(f"  - {table[0]}")
        
        # Check if alembic_version table exists (indicates migrations applied)
        cursor.execute("SELECT * FROM sqlite_master WHERE name='alembic_version'")
        alembic_table = cursor.fetchone()
        if alembic_table:
            print(f"\n✅ Alembic migrations have been applied")
            cursor.execute("SELECT * FROM alembic_version")
            version = cursor.fetchone()
            print(f"   Current migration version: {version[0] if version else 'Unknown'}")
        else:
            print(f"\n⚠️  Alembic version table not found - migrations may not be applied")
        
        # Check for key tables from models
        key_tables = ['users', 'deliverables', 'sprints', 'signoffs', 'user_profiles', 'user_settings']
        print(f"\n🔍 Checking key application tables:")
        
        for table in key_tables:
            cursor.execute(f"SELECT name FROM sqlite_master WHERE type='table' AND name='{table}'")
            exists = cursor.fetchone()
            if exists:
                print(f"  ✅ {table} table exists")
                # Count rows
                cursor.execute(f"SELECT COUNT(*) FROM {table}")
                count = cursor.fetchone()[0]
                print(f"     Rows: {count}")
            else:
                print(f"  ❌ {table} table does not exist")
        
        # Show registered users
        print(f"\n👥 Registered users:")
        cursor.execute("SELECT id, email, first_name, last_name FROM users")
        users = cursor.fetchall()
        for user in users:
            print(f"  ID: {user[0]}, Email: {user[1]}, Name: {user[2]} {user[3]}")
        
        conn.close()
        
    except sqlite3.Error as e:
        print(f"❌ Database error: {e}")

if __name__ == "__main__":
    check_database()