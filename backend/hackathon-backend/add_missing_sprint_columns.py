from sqlalchemy import create_engine, text
import os

# Create engine using the correct database path
BASE_DIR = os.path.dirname(os.path.abspath('.'))
DATABASE_PATH = os.path.join(BASE_DIR, 'hackathon.db')
DATABASE_URL = f'sqlite:///{DATABASE_PATH}'
engine = create_engine(DATABASE_URL)

# List of missing columns to add to sprints table
missing_columns = [
    "planned_points INTEGER",
    "committed_points INTEGER", 
    "completed_points INTEGER",
    "carried_over_points INTEGER",
    "added_during_sprint INTEGER",
    "removed_during_sprint INTEGER",
    "test_pass_rate INTEGER",
    "code_coverage INTEGER",
    "escaped_defects INTEGER",
    "defects_opened INTEGER",
    "defects_closed INTEGER",
    "defect_severity_mix JSON",
    "code_review_completion INTEGER",
    "documentation_status VARCHAR(50)",
    "uat_notes TEXT",
    "uat_pass_rate INTEGER",
    "risks_identified INTEGER",
    "risks_mitigated INTEGER",
    "blockers TEXT",
    "decisions TEXT",
    "created_by VARCHAR(255)",
    "reviewed_at DATETIME"
]

# Add each missing column
try:
    with engine.connect() as conn:
        for column_def in missing_columns:
            try:
                sql = f"ALTER TABLE sprints ADD COLUMN {column_def}"
                conn.execute(text(sql))
                print(f"Added column: {column_def.split()[0]}")
            except Exception as e:
                print(f"Failed to add column {column_def.split()[0]}: {e}")
        
        conn.commit()
        print("All missing columns added successfully!")
        
except Exception as e:
    print(f"Error: {e}")