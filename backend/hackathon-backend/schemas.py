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
        orm_mode = True

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
        orm_mode = True

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
        orm_mode = True

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
        orm_mode = True

# Update forward references
Sprint.model_rebuild()

# Settings schemas
class SettingsBase(BaseModel):
    dark_mode: bool = False
    notifications_enabled: bool = True
    language: str = "English"
    sync_on_mobile_data: bool = False
    auto_backup: bool = False
    share_analytics: bool = False
    allow_notifications: bool = True

class SettingsCreate(SettingsBase):
    pass

class SettingsUpdate(SettingsBase):
    dark_mode: Optional[bool] = None
    notifications_enabled: Optional[bool] = None
    language: Optional[str] = None
    sync_on_mobile_data: Optional[bool] = None
    auto_backup: Optional[bool] = None
    share_analytics: Optional[bool] = None
    allow_notifications: Optional[bool] = None

class SettingsResponse(SettingsBase):
    user_id: str
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True


# User Profile schemas
class UserProfileBase(BaseModel):
    user_id: str
    first_name: str
    last_name: str
    email: EmailStr
    phone_number: Optional[str] = None
    profile_picture: Optional[str] = None
    bio: Optional[str] = None
    job_title: Optional[str] = None
    company: Optional[str] = None
    location: Optional[str] = None
    website: Optional[str] = None
    date_of_birth: Optional[datetime] = None

class UserProfileCreate(UserProfileBase):
    pass

class UserProfileUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    email: Optional[EmailStr] = None
    phone_number: Optional[str] = None
    profile_picture: Optional[str] = None
    bio: Optional[str] = None
    job_title: Optional[str] = None
    company: Optional[str] = None
    location: Optional[str] = None
    website: Optional[str] = None
    date_of_birth: Optional[datetime] = None

class UserProfile(UserProfileBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True
