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
    definition_of_done: Optional[str] = None
    priority: str = "medium"  # low, medium, high, critical
    due_date: Optional[datetime] = None
    status: str = "draft"  # draft, in_progress, submitted, approved, change_requested
    created_by: Optional[str] = None
    assigned_to: Optional[str] = None
    
    # Evidence links
    evidence_links: Optional[List[str]] = []
    demo_link: Optional[str] = None
    repo_link: Optional[str] = None
    test_summary_link: Optional[str] = None
    user_guide_link: Optional[str] = None
    
    # Quality metrics
    test_pass_rate: Optional[int] = None  # Percentage
    code_coverage: Optional[int] = None  # Percentage
    escaped_defects: Optional[int] = None
    defect_severity_mix: Optional[Dict[str, int]] = None  # {critical: 1, high: 2, medium: 3, low: 4}
    
    # Timestamps for workflow
    submitted_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None

class DeliverableCreate(DeliverableBase):
    pass

class DeliverableUpdate(BaseModel):
    title: Optional[str] = None
    description: Optional[str] = None
    definition_of_done: Optional[str] = None
    priority: Optional[str] = None
    due_date: Optional[datetime] = None
    status: Optional[str] = None
    assigned_to: Optional[str] = None
    
    # Evidence links
    evidence_links: Optional[List[str]] = None
    demo_link: Optional[str] = None
    repo_link: Optional[str] = None
    test_summary_link: Optional[str] = None
    user_guide_link: Optional[str] = None
    
    # Quality metrics
    test_pass_rate: Optional[int] = None
    code_coverage: Optional[int] = None
    escaped_defects: Optional[int] = None
    defect_severity_mix: Optional[Dict[str, int]] = None
    
    # Timestamps for workflow
    submitted_at: Optional[datetime] = None
    approved_at: Optional[datetime] = None

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
    
    # Sprint planning
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    planned_points: Optional[int] = 0
    committed_points: Optional[int] = 0
    
    # Sprint outcomes
    completed_points: Optional[int] = 0
    carried_over_points: Optional[int] = 0
    added_during_sprint: Optional[int] = 0
    removed_during_sprint: Optional[int] = 0
    
    # Quality metrics
    test_pass_rate: Optional[int] = None  # Percentage
    code_coverage: Optional[int] = None  # Percentage
    escaped_defects: Optional[int] = None
    defects_opened: Optional[int] = None
    defects_closed: Optional[int] = None
    defect_severity_mix: Optional[Dict[str, int]] = None  # {critical: 1, high: 2, medium: 3, low: 4}
    code_review_completion: Optional[int] = None  # Percentage
    documentation_status: Optional[str] = None  # complete, partial, missing
    
    # UAT and acceptance
    uat_notes: Optional[str] = None
    uat_pass_rate: Optional[int] = None  # Percentage
    
    # Risk management
    risks_identified: Optional[int] = None
    risks_mitigated: Optional[int] = None
    blockers: Optional[str] = None
    decisions: Optional[str] = None
    
    status: str = "planning"  # planning, active, completed, reviewed
    created_by: Optional[str] = None

class SprintCreate(SprintBase):
    pass

class SprintUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    
    # Sprint planning
    start_date: Optional[datetime] = None
    end_date: Optional[datetime] = None
    planned_points: Optional[int] = None
    committed_points: Optional[int] = None
    
    # Sprint outcomes
    completed_points: Optional[int] = None
    carried_over_points: Optional[int] = None
    added_during_sprint: Optional[int] = None
    removed_during_sprint: Optional[int] = None
    
    # Quality metrics
    test_pass_rate: Optional[int] = None
    code_coverage: Optional[int] = None
    escaped_defects: Optional[int] = None
    defects_opened: Optional[int] = None
    defects_closed: Optional[int] = None
    defect_severity_mix: Optional[Dict[str, int]] = None
    code_review_completion: Optional[int] = None
    documentation_status: Optional[str] = None
    
    # UAT and acceptance
    uat_notes: Optional[str] = None
    uat_pass_rate: Optional[int] = None
    
    # Risk management
    risks_identified: Optional[int] = None
    risks_mitigated: Optional[int] = None
    blockers: Optional[str] = None
    decisions: Optional[str] = None
    
    status: Optional[str] = None
    created_by: Optional[str] = None
    reviewed_at: Optional[datetime] = None

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
    entity_type: str  # sprint, deliverable
    entity_id: int
    signer_name: str
    signer_email: EmailStr
    signer_role: Optional[str] = None
    signer_company: Optional[str] = None
    decision: str = "pending"  # pending, approved, change_requested, rejected
    comments: Optional[str] = None
    change_request_details: Optional[str] = None

class SignoffCreate(SignoffBase):
    pass

class SignoffUpdate(BaseModel):
    entity_type: Optional[str] = None
    entity_id: Optional[int] = None
    signer_name: Optional[str] = None
    signer_email: Optional[EmailStr] = None
    signer_role: Optional[str] = None
    signer_company: Optional[str] = None
    decision: Optional[str] = None
    comments: Optional[str] = None
    change_request_details: Optional[str] = None

class Signoff(SignoffBase):
    id: int
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    signature_hash: Optional[str] = None
    submitted_at: datetime
    reviewed_at: Optional[datetime] = None
    responded_at: Optional[datetime] = None
    
    class Config:
        orm_mode = True

# Audit log schemas
class AuditLogBase(BaseModel):
    entity_type: str
    entity_id: int
    action: str
    user_email: Optional[str] = None
    user_role: Optional[str] = None
    session_id: Optional[str] = None
    ip_address: Optional[str] = None
    user_agent: Optional[str] = None
    action_category: Optional[str] = None
    entity_name: Optional[str] = None
    old_values: Optional[Dict] = None
    new_values: Optional[Dict] = None
    changed_fields: Optional[Dict] = None
    request_id: Optional[str] = None
    endpoint: Optional[str] = None
    http_method: Optional[str] = None
    status_code: Optional[int] = None

class AuditLogCreate(AuditLogBase):
    pass

class AuditLog(AuditLogBase):
    id: int
    created_at: datetime
    
    class Config:
        orm_mode = True
        
    @classmethod
    def from_orm(cls, obj):
        # Convert the ORM object to a dictionary and handle field mapping
        data = {
            'id': obj.id,
            'created_at': obj.created_at,
            'entity_type': obj.entity_type,
            'entity_id': obj.entity_id,
            'action': obj.action,
            'user_email': obj.user_email,
            'user_role': obj.user_role,
            'session_id': obj.session_id,
            'ip_address': obj.ip_address,
            'user_agent': obj.user_agent,
            'action_category': obj.action_category,
            'entity_name': obj.entity_name,
            'old_values': obj.old_values,
            'new_values': obj.new_values,
            'changed_fields': obj.changed_fields,
            'request_id': obj.request_id,
            'endpoint': obj.endpoint,
            'http_method': obj.http_method,
            'status_code': obj.status_code
        }
        # Remove None values to avoid validation errors
        data = {k: v for k, v in data.items() if v is not None}
        return cls(**data)

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
