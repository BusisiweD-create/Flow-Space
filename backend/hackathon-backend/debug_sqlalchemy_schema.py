"""
Debug script to check what SQLAlchemy sees in the database schema
"""

import os
from sqlalchemy import create_engine, text, inspect
from sqlalchemy.orm import sessionmaker
from database import DATABASE_URL, engine
from models import Sprint

def debug_database_schema():
    print(f"Database URL: {DATABASE_URL}")
    
    # Check if database file exists
    if "sqlite" in DATABASE_URL:
        db_path = DATABASE_URL.replace("sqlite:///", "")
        print(f"Database file path: {db_path}")
        print(f"Database file exists: {os.path.exists(db_path)}")
        if os.path.exists(db_path):
            print(f"Database file size: {os.path.getsize(db_path)} bytes")
    
    # Create inspector to check actual database schema
    inspector = inspect(engine)
    
    print("\n=== Tables in database ===")
    tables = inspector.get_table_names()
    for table in tables:
        print(f"- {table}")
    
    print("\n=== Sprints table columns (via inspector) ===")
    if 'sprints' in tables:
        columns = inspector.get_columns('sprints')
        for col in columns:
            print(f"- {col['name']}: {col['type']}")
    else:
        print("sprints table not found!")
    
    # Check SQLAlchemy model columns
    print("\n=== Sprint model columns (via SQLAlchemy) ===")
    for column in Sprint.__table__.columns:
        print(f"- {column.name}: {column.type}")
    
    # Try to execute a simple query
    print("\n=== Testing database connection ===")
    try:
        with engine.connect() as conn:
            result = conn.execute(text("SELECT name FROM sqlite_master WHERE type='table' AND name='sprints'"))
            sprints_exists = result.fetchone()
            print(f"Sprints table exists (via SQL): {sprints_exists is not None}")
            
            if sprints_exists:
                # Check columns via PRAGMA
                result = conn.execute(text("PRAGMA table_info(sprints)"))
                columns = result.fetchall()
                print("\n=== Sprints table columns (via PRAGMA) ===")
                for col in columns:
                    print(f"- {col[1]}: {col[2]}")  # name: type
                
                # Try to query planned_points specifically
                try:
                    result = conn.execute(text("SELECT planned_points FROM sprints LIMIT 1"))
                    print("\n✓ planned_points column is accessible via direct SQL")
                except Exception as e:
                    print(f"\n✗ Error accessing planned_points: {e}")
    
    except Exception as e:
        print(f"Database connection error: {e}")
    
    # Test SQLAlchemy ORM query
    print("\n=== Testing SQLAlchemy ORM query ===")
    try:
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Try to query using ORM
        result = db.query(Sprint.id, Sprint.name).limit(1).all()
        print(f"✓ Basic Sprint query successful: {len(result)} rows")
        
        # Try to query planned_points specifically
        result = db.query(Sprint.planned_points).limit(1).all()
        print(f"✓ planned_points query successful: {len(result)} rows")
        
        db.close()
        
    except Exception as e:
        print(f"✗ SQLAlchemy ORM query error: {e}")

if __name__ == "__main__":
    debug_database_schema()