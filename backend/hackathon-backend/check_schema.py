#!/usr/bin/env python3
"""
Script to check the current database schema and verify if columns exist
"""

import sqlite3
import sys

def check_deliverables_schema():
    """Check the schema of the deliverables table"""
    try:
        # Connect to the database
        conn = sqlite3.connect('hackathon.db')
        cursor = conn.cursor()
        
        # Get the schema information for deliverables table
        cursor.execute("PRAGMA table_info(deliverables)")
        columns = cursor.fetchall()
        
        print("Columns in deliverables table:")
        for col in columns:
            print(f"  {col[1]} ({col[2]}) - {'NULL' if col[3] else 'NOT NULL'}")
        
        # Check if definition_of_done column exists
        definition_of_done_exists = any(col[1] == 'definition_of_done' for col in columns)
        print(f"\nDefinition of done column exists: {definition_of_done_exists}")
        
        conn.close()
        return definition_of_done_exists
        
    except Exception as e:
        print(f"Error checking schema: {e}")
        return False

if __name__ == "__main__":
    check_deliverables_schema()