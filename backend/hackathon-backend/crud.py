"""
CRUD operations for database models
"""

from sqlalchemy.orm import Session
from typing import List, Optional
from models import Deliverable, Sprint, Signoff, AuditLog, UserProfile
from schemas import (
    DeliverableCreate, DeliverableUpdate,
    SprintCreate, SprintUpdate,
    SignoffCreate, SignoffUpdate,
    AuditLogCreate,
    UserProfileCreate, UserProfileUpdate
)

# Deliverable CRUD operations
def get_deliverable(db: Session, deliverable_id: int) -> Optional[Deliverable]:
    return db.query(Deliverable).filter(Deliverable.id == deliverable_id).first()

def get_deliverables(db: Session, skip: int = 0, limit: int = 100) -> List[Deliverable]:
    return db.query(Deliverable).offset(skip).limit(limit).all()

def get_deliverables_by_sprint(db: Session, sprint_id: int) -> List[Deliverable]:
    return db.query(Deliverable).filter(Deliverable.sprint_id == sprint_id).all()

def create_deliverable(db: Session, deliverable: DeliverableCreate) -> Deliverable:
    db_deliverable = Deliverable(**deliverable.dict())
    db.add(db_deliverable)
    db.commit()
    db.refresh(db_deliverable)
    return db_deliverable

def update_deliverable(db: Session, deliverable_id: int, deliverable: DeliverableUpdate) -> Optional[Deliverable]:
    db_deliverable = db.query(Deliverable).filter(Deliverable.id == deliverable_id).first()
    if db_deliverable:
        update_data = deliverable.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_deliverable, field, value)
        db.commit()
        db.refresh(db_deliverable)
    return db_deliverable

def delete_deliverable(db: Session, deliverable_id: int) -> bool:
    db_deliverable = db.query(Deliverable).filter(Deliverable.id == deliverable_id).first()
    if db_deliverable:
        db.delete(db_deliverable)
        db.commit()
        return True
    return False

# Sprint CRUD operations
def get_sprint(db: Session, sprint_id: int) -> Optional[Sprint]:
    return db.query(Sprint).filter(Sprint.id == sprint_id).first()

def get_sprints(db: Session, skip: int = 0, limit: int = 100) -> List[Sprint]:
    return db.query(Sprint).offset(skip).limit(limit).all()

def create_sprint(db: Session, sprint: SprintCreate) -> Sprint:
    db_sprint = Sprint(**sprint.dict())
    db.add(db_sprint)
    db.commit()
    db.refresh(db_sprint)
    return db_sprint

def update_sprint(db: Session, sprint_id: int, sprint: SprintUpdate) -> Optional[Sprint]:
    db_sprint = db.query(Sprint).filter(Sprint.id == sprint_id).first()
    if db_sprint:
        update_data = sprint.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_sprint, field, value)
        db.commit()
        db.refresh(db_sprint)
    return db_sprint

def delete_sprint(db: Session, sprint_id: int) -> bool:
    db_sprint = db.query(Sprint).filter(Sprint.id == sprint_id).first()
    if db_sprint:
        db.delete(db_sprint)
        db.commit()
        return True
    return False

# Signoff CRUD operations
def get_signoff(db: Session, signoff_id: int) -> Optional[Signoff]:
    return db.query(Signoff).filter(Signoff.id == signoff_id).first()

def get_signoffs_by_sprint(db: Session, sprint_id: int) -> List[Signoff]:
    return db.query(Signoff).filter(Signoff.sprint_id == sprint_id).all()

def create_signoff(db: Session, signoff: SignoffCreate) -> Signoff:
    db_signoff = Signoff(**signoff.dict())
    db.add(db_signoff)
    db.commit()
    db.refresh(db_signoff)
    return db_signoff

def update_signoff(db: Session, signoff_id: int, signoff: SignoffUpdate) -> Optional[Signoff]:
    db_signoff = db.query(Signoff).filter(Signoff.id == signoff_id).first()
    if db_signoff:
        update_data = signoff.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_signoff, field, value)
        db.commit()
        db.refresh(db_signoff)
    return db_signoff

def delete_signoff(db: Session, signoff_id: int) -> bool:
    db_signoff = db.query(Signoff).filter(Signoff.id == signoff_id).first()
    if db_signoff:
        db.delete(db_signoff)
        db.commit()
        return True
    return False

# Audit log CRUD operations
def create_audit_log(db: Session, audit_log: AuditLogCreate) -> AuditLog:
    db_audit_log = AuditLog(**audit_log.dict())
    db.add(db_audit_log)
    db.commit()
    db.refresh(db_audit_log)
    return db_audit_log

def get_audit_logs(db: Session, skip: int = 0, limit: int = 100) -> List[AuditLog]:
    return db.query(AuditLog).offset(skip).limit(limit).all()

def get_audit_logs_by_entity(db: Session, entity_type: str, entity_id: int) -> List[AuditLog]:
    return db.query(AuditLog).filter(
        AuditLog.entity_type == entity_type,
        AuditLog.entity_id == entity_id
    ).all()


# User Profile CRUD operations
def get_user_profile(db: Session, user_id: str) -> Optional[UserProfile]:
    return db.query(UserProfile).filter(UserProfile.user_id == user_id).first()

def get_user_profile_by_email(db: Session, email: str) -> Optional[UserProfile]:
    return db.query(UserProfile).filter(UserProfile.email == email).first()

def get_user_profiles(db: Session, skip: int = 0, limit: int = 100) -> List[UserProfile]:
    return db.query(UserProfile).offset(skip).limit(limit).all()

def create_user_profile(db: Session, profile: UserProfileCreate) -> UserProfile:
    db_profile = UserProfile(**profile.dict())
    db.add(db_profile)
    db.commit()
    db.refresh(db_profile)
    return db_profile

def update_user_profile(db: Session, user_id: str, profile: UserProfileUpdate) -> Optional[UserProfile]:
    db_profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if db_profile:
        update_data = profile.dict(exclude_unset=True)
        for field, value in update_data.items():
            setattr(db_profile, field, value)
        db.commit()
        db.refresh(db_profile)
    return db_profile

def delete_user_profile(db: Session, user_id: str) -> bool:
    db_profile = db.query(UserProfile).filter(UserProfile.user_id == user_id).first()
    if db_profile:
        db.delete(db_profile)
        db.commit()
        return True
    return False
