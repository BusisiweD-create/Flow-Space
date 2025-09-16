"""
Pydantic schemas for request/response models
"""

from pydantic import BaseModel, EmailStr
from datetime import datetime
from typing import Optional, List

# Base schemas
class DeliverableBase(BaseModel):
    title: str
    description: Optional[str] = None
    status: str = "pending"
    sprint_id: Optional[int] = None

class DeliverableCreate(DeliverableBase):
    pass

class DeliverableUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    status: Optional[str] = None
    sprint_id: Optional[int] = None

class Deliverable(DeliverableBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        from_attributes = True

# Sprint schemas
class SprintBase(BaseModel):
    name: str
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    status: str = "planning"

class SprintCreate(SprintBase):
    pass

class SprintUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    status: Optional[str] = None

class Sprint(SprintBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    deliverables: List[Deliverable] = []
    signoffs: List["Signoff"] = []
    
    class Config:
        from_attributes = True

# Signoff schemas
class SignoffBase(BaseModel):
    sprint_id: int
    signer_name: str
    signer_email: EmailStr
    comments: Optional[str] = None
    is_approved: bool = False

class SignoffCreate(SignoffBase):
    pass

class SignoffUpdate(BaseModel):
    signer_name: Optional[str] = None
    signer_email: Optional[EmailStr] = None
    comments: Optional[str] = None
    is_approved: Optional[bool] = None

class Signoff(SignoffBase):
    id: int
    signed_at: datetime
    
    class Config:
        from_attributes = True

# Audit log schemas
class AuditLogBase(BaseModel):
    entity_type: str
    entity_id: int
    action: str
    user: Optional[str] = None
    details: Optional[str] = None

class AuditLogCreate(AuditLogBase):
    pass

class AuditLog(AuditLogBase):
    id: int
    timestamp: datetime
    
    class Config:
        from_attributes = True

# Update forward references
Sprint.model_rebuild()
