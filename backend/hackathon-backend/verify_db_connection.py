from sqlalchemy import create_engine, inspect
import os

# Get the exact database URL that the server is using
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DEFAULT_SQLITE_PATH = os.path.join(BASE_DIR, "hackathon.db")
DATABASE_URL = os.getenv("DATABASE_URL") or f"sqlite:///{DEFAULT_SQLITE_PATH}"

print(f"Database URL: {DATABASE_URL}")
print(f"Database file exists: {os.path.exists(DEFAULT_SQLITE_PATH)}")
print(f"Database file size: {os.path.getsize(DEFAULT_SQLITE_PATH) if os.path.exists(DEFAULT_SQLITE_PATH) else 'N/A'} bytes")

# Create engine and check connection
engine = create_engine(
    DATABASE_URL,
    connect_args={"check_same_thread": False} if "sqlite" in DATABASE_URL else {}
)

# Test connection and list tables
try:
    with engine.connect() as conn:
        print("Database connection successful")
        
        # List all tables
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"Tables in database: {tables}")
        
        # Check sprints table specifically
        if 'sprints' in tables:
            print("Sprints table exists")
            columns = inspector.get_columns('sprints')
            print("Sprints table columns:")
            for col in columns:
                print(f"  {col['name']}: {col['type']}")
        else:
            print("Sprints table does NOT exist")
            
except Exception as e:
    print(f"Database connection failed: {e}")