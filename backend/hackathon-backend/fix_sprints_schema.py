"""
Fix sprints table schema by adding all missing columns
"""

import sqlite3
import os

def fix_sprints_schema():
    db_path = "hackathon.db"
    
    if not os.path.exists(db_path):
        print(f"Database file {db_path} not found!")
        return
    
    # Connect to database
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Get current columns
    cursor.execute("PRAGMA table_info(sprints)")
    current_columns = [row[1] for row in cursor.fetchall()]
    print(f"Current columns: {current_columns}")
    
    # Define all required columns with their types
    required_columns = {
        'planned_points': 'INTEGER',
        'committed_points': 'INTEGER', 
        'completed_points': 'INTEGER',
        'carried_over_points': 'INTEGER',
        'added_during_sprint': 'INTEGER',
        'removed_during_sprint': 'INTEGER',
        'test_pass_rate': 'INTEGER',
        'code_coverage': 'INTEGER',
        'escaped_defects': 'INTEGER',
        'defects_opened': 'INTEGER',
        'defects_closed': 'INTEGER',
        'defect_severity_mix': 'TEXT',  # JSON stored as TEXT in SQLite
        'code_review_completion': 'INTEGER',
        'documentation_status': 'VARCHAR(50)',
        'uat_notes': 'TEXT',
        'uat_pass_rate': 'INTEGER',
        'risks_identified': 'INTEGER',
        'risks_mitigated': 'INTEGER',
        'blockers': 'TEXT',
        'decisions': 'TEXT',
        'created_by': 'VARCHAR(255)',
        'reviewed_at': 'DATETIME'
    }
    
    # Add missing columns
    added_columns = []
    for column_name, column_type in required_columns.items():
        if column_name not in current_columns:
            try:
                sql = f"ALTER TABLE sprints ADD COLUMN {column_name} {column_type}"
                print(f"Adding column: {sql}")
                cursor.execute(sql)
                added_columns.append(column_name)
                print(f"✓ Added {column_name}")
            except sqlite3.OperationalError as e:
                print(f"✗ Error adding {column_name}: {e}")
        else:
            print(f"- Column {column_name} already exists")
    
    # Commit changes
    conn.commit()
    
    # Verify the changes
    print("\n=== Verification ===")
    cursor.execute("PRAGMA table_info(sprints)")
    final_columns = [row[1] for row in cursor.fetchall()]
    print(f"Final columns count: {len(final_columns)}")
    print(f"Added columns: {added_columns}")
    
    # Test querying the new columns
    print("\n=== Testing new columns ===")
    for column in ['planned_points', 'committed_points', 'completed_points']:
        try:
            cursor.execute(f"SELECT {column} FROM sprints LIMIT 1")
            print(f"✓ {column} is accessible")
        except sqlite3.OperationalError as e:
            print(f"✗ {column} error: {e}")
    
    conn.close()
    print("\nSchema fix completed!")

if __name__ == "__main__":
    fix_sprints_schema()