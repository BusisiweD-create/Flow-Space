"""
Pydantic schemas for request/response models
"""

from typing import List, Optional, Dict
from datetime import datetime, date
from pydantic import BaseModel, EmailStr, Field

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
    
    # Enhanced profile fields
    headline: Optional[str] = None
    skills: Optional[str] = None  # JSON string of skills
    experience_years: Optional[int] = None
    education: Optional[str] = None  # JSON string of education history
    social_links: Optional[str] = None  # JSON string of social media links
    availability_status: Optional[str] = "available"
    timezone: Optional[str] = None
    preferred_language: Optional[str] = None
    
    # Verification status
    is_email_verified: Optional[bool] = False
    is_phone_verified: Optional[bool] = False
    verification_badge: Optional[bool] = False
    
    # Privacy settings
    profile_visibility: Optional[str] = "public"
    show_email: Optional[bool] = False
    show_phone: Optional[bool] = False
    last_active_at: Optional[datetime] = None

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
    
    # Enhanced profile fields
    headline: Optional[str] = None
    skills: Optional[str] = None
    experience_years: Optional[int] = None
    education: Optional[str] = None
    social_links: Optional[str] = None
    availability_status: Optional[str] = None
    timezone: Optional[str] = None
    preferred_language: Optional[str] = None
    
    # Verification status
    is_email_verified: Optional[bool] = None
    is_phone_verified: Optional[bool] = None
    verification_badge: Optional[bool] = None
    
    # Privacy settings
    profile_visibility: Optional[str] = None
    show_email: Optional[bool] = None
    show_phone: Optional[bool] = None
    last_active_at: Optional[datetime] = None

# Authentication schemas
class Token(BaseModel):
    access_token: str
    token_type: str = "bearer"
    refresh_token: Optional[str] = None
    expires_in: int

class TokenData(BaseModel):
    email: Optional[str] = None
    user_id: Optional[int] = None
    role: Optional[str] = None

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class UserRegister(BaseModel):
    email: EmailStr
    password: str
    first_name: str
    last_name: str
    company: Optional[str] = None
    role: str = "user"

class UserBase(BaseModel):
    email: EmailStr
    first_name: str
    last_name: str
    company: Optional[str] = None
    role: str = "user"
    is_active: bool = True
    is_verified: bool = False

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    first_name: Optional[str] = None
    last_name: Optional[str] = None
    company: Optional[str] = None
    role: Optional[str] = None
    is_active: Optional[bool] = None

class User(UserBase):
    id: int
    last_login: Optional[datetime] = None
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True

class RefreshTokenCreate(BaseModel):
    token: str
    user_id: int
    expires_at: datetime

class RefreshToken(BaseModel):
    id: int
    user_id: int
    token: str
    expires_at: datetime
    is_revoked: bool = False
    created_at: datetime
    
    class Config:
        orm_mode = True

class UserProfile(UserProfileBase):
    id: int
    created_at: datetime
    updated_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True


class NotificationBase(BaseModel):
    recipient_id: int
    sender_id: Optional[int] = None
    type: str
    message: str
    payload: Optional[Dict] = None
    is_read: bool = False


class NotificationCreate(NotificationBase):
    pass


class Notification(NotificationBase):
    id: int
    created_at: datetime

    class Config:
        orm_mode = True


# File upload schemas
class FileUploadResponse(BaseModel):
    """Response schema for file upload"""
    filename: str
    url: str
    size: int
    storage_provider: str
    
    class Config:
        from_attributes = True


class PresignedUrlResponse(BaseModel):
    """Response schema for presigned URL"""
    filename: str
    presigned_url: str
    expires_at: datetime
    
    class Config:
        from_attributes = True


class FileInfo(BaseModel):
    """File information schema"""
    filename: str
    original_name: str
    size: int
    content_type: str
    upload_date: datetime
    storage_provider: str
    
    class Config:
        from_attributes = True
