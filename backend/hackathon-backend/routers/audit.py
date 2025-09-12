"""
Router for audit log-related endpoints
"""

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
from database import get_db
from schemas import AuditLog, AuditLogCreate
from crud import (
    create_audit_log, get_audit_logs, get_audit_logs_by_entity
)

router = APIRouter()

@router.get("/", response_model=List[AuditLog])
def read_audit_logs(
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db)
):
    """Get all audit logs with pagination"""
    audit_logs = get_audit_logs(db, skip=skip, limit=limit)
    return audit_logs

@router.get("/entity/{entity_type}/{entity_id}", response_model=List[AuditLog])
def read_audit_logs_by_entity(
    entity_type: str,
    entity_id: int,
    db: Session = Depends(get_db)
):
    """Get audit logs for a specific entity"""
    audit_logs = get_audit_logs_by_entity(
        db, entity_type=entity_type, entity_id=entity_id
    )
    return audit_logs

@router.post("/", response_model=AuditLog, status_code=status.HTTP_201_CREATED)
def create_new_audit_log(
    audit_log: AuditLogCreate,
    db: Session = Depends(get_db)
):
    """Create a new audit log entry"""
    return create_audit_log(db=db, audit_log=audit_log)

@router.get("/deliverable/{deliverable_id}", response_model=List[AuditLog])
def read_deliverable_audit_logs(
    deliverable_id: int,
    db: Session = Depends(get_db)
):
    """Get audit logs for a specific deliverable"""
    return read_audit_logs_by_entity("deliverable", deliverable_id, db)

@router.get("/sprint/{sprint_id}", response_model=List[AuditLog])
def read_sprint_audit_logs(
    sprint_id: int,
    db: Session = Depends(get_db)
):
    """Get audit logs for a specific sprint"""
    return read_audit_logs_by_entity("sprint", sprint_id, db)

@router.get("/signoff/{signoff_id}", response_model=List[AuditLog])
def read_signoff_audit_logs(
    signoff_id: int,
    db: Session = Depends(get_db)
):
    """Get audit logs for a specific signoff"""
    return read_audit_logs_by_entity("signoff", signoff_id, db)
