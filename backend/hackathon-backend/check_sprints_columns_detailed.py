import sqlite3
import os

# Connect to the database directly
BASE_DIR = os.path.dirname(os.path.abspath('.'))
DATABASE_PATH = os.path.join(BASE_DIR, 'hackathon.db')

# Connect to SQLite database
conn = sqlite3.connect(DATABASE_PATH)
cursor = conn.cursor()

# Get all columns from sprints table
cursor.execute("PRAGMA table_info(sprints)")
columns = cursor.fetchall()

print("Sprints table columns:")
for column in columns:
    print(f"  {column[1]}: {column[2]} {'NOT NULL' if column[3] else 'NULL'} {'PRIMARY KEY' if column[5] else ''}")

# Also check if we can query the problematic columns
try:
    cursor.execute("SELECT planned_points, committed_points, completed_points FROM sprints LIMIT 1")
    print("\nSuccessfully queried planned_points, committed_points, completed_points")
except sqlite3.OperationalError as e:
    print(f"\nQuery failed: {e}")

conn.close()