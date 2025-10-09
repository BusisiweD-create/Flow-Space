from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import AuditLog, Base
from database import engine

# Create a session
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
db = SessionLocal()

# Create a test audit log entry
try:
    audit_log = AuditLog(
        entity_type="test",
        entity_id=1,
        action="test_action",
        user_email="test@example.com",
        new_values={"test": "value"}
    )
    db.add(audit_log)
    db.commit()
    db.refresh(audit_log)
    
    print("Audit log created successfully:")
    print(f"ID: {audit_log.id}")
    print(f"Action: {audit_log.action}")
    print(f"User email: {audit_log.user_email}")
    print(f"Created at: {audit_log.created_at}")
    print(f"All attributes:")
    for attr in dir(audit_log):
        if not attr.startswith('_'):
            value = getattr(audit_log, attr)
            if not callable(value):
                print(f"  {attr}: {value}")
    
    # Check what the object looks like when converted to dict
    print("\nAs dictionary:")
    audit_dict = {}
    for attr in dir(audit_log):
        if not attr.startswith('_'):
            value = getattr(audit_log, attr)
            if not callable(value):
                audit_dict[attr] = value
    print(audit_dict)
    
except Exception as e:
    print(f"Error: {e}")
    db.rollback()
finally:
    db.close()