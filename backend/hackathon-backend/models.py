"""
SQLAlchemy database models
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Date, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from datetime import datetime

Base = declarative_base()

class Deliverable(Base):
    """Model for project deliverables"""
    __tablename__ = "deliverables"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    status = Column(String(50), default="pending")  # pending, in_progress, completed
    sprint_id = Column(Integer, ForeignKey("sprints.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    sprint = relationship("Sprint", back_populates="deliverables")

class Sprint(Base):
    """Model for project sprints"""
    __tablename__ = "sprints"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    start_date = Column(DateTime(timezone=True))
    end_date = Column(DateTime(timezone=True))
    status = Column(String(50), default="planning")  # planning, active, completed
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    deliverables = relationship("Deliverable", back_populates="sprint")
    signoffs = relationship("Signoff", back_populates="sprint")

class Signoff(Base):
    """Model for sprint signoffs"""
    __tablename__ = "signoffs"
    
    id = Column(Integer, primary_key=True, index=True)
    sprint_id = Column(Integer, ForeignKey("sprints.id"))
    signer_name = Column(String(255), nullable=False)
    signer_email = Column(String(255), nullable=False)
    comments = Column(Text)
    is_approved = Column(Boolean, default=False)
    signed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    sprint = relationship("Sprint", back_populates="signoffs")

class AuditLog(Base):
    """Model for audit logging"""
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    entity_type = Column(String(100), nullable=False)  # deliverable, sprint, signoff
    entity_id = Column(Integer, nullable=False)
    action = Column(String(100), nullable=False)  # create, update, delete, signoff
    user = Column(String(255))
    details = Column(Text)
    timestamp = Column(DateTime(timezone=True), server_default=func.now())

class UserSettings(Base):
    """Model for user settings and preferences"""
    __tablename__ = "user_settings"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(String(255), nullable=False, index=True)  # Could be email or username
    dark_mode = Column(Boolean, default=False)
    notifications_enabled = Column(Boolean, default=True)
    language = Column(String(50), default='English')
    sync_on_mobile_data = Column(Boolean, default=False)
    auto_backup = Column(Boolean, default=False)
    share_analytics = Column(Boolean, default=False)
    allow_notifications = Column(Boolean, default=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())


class User(Base):
    """Model for user authentication"""
    __tablename__ = "users"
    
    id = Column(Integer, primary_key=True, index=True)
    email = Column(String(255), nullable=False, unique=True, index=True)
    hashed_password = Column(String(255), nullable=False)
    first_name = Column(String(100), nullable=False)
    last_name = Column(String(100), nullable=False)
    company = Column(String(100))
    role = Column(String(50), default="user")  # admin, manager, user, client
    is_active = Column(Boolean, default=True)
    is_verified = Column(Boolean, default=False)
    verification_token = Column(String(255))
    reset_token = Column(String(255))
    last_login = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    profile = relationship("UserProfile", back_populates="user", uselist=False)

class RefreshToken(Base):
    """Model for refresh tokens"""
    __tablename__ = "refresh_tokens"
    
    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable=False)
    token = Column(String(500), nullable=False, unique=True)
    expires_at = Column(DateTime(timezone=True), nullable=False)
    is_revoked = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships
    user = relationship("User")

class UserProfile(Base):
    __tablename__ = "user_profiles"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), unique=True, index=True)
    first_name = Column(String, index=True)
    last_name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    phone_number = Column(String, nullable=True)
    profile_picture = Column(String, nullable=True)
    bio = Column(String, nullable=True)
    job_title = Column(String, nullable=True)
    company = Column(String, nullable=True)
    location = Column(String, nullable=True)
    website = Column(String, nullable=True)
    date_of_birth = Column(Date, nullable=True)
    headline = Column(String, nullable=True)
    skills = Column(JSON, nullable=True)  # Store as JSON array of strings
    experience_years = Column(Integer, nullable=True)
    education = Column(JSON, nullable=True)  # Store as JSON array of objects
    social_links = Column(JSON, nullable=True)  # Store as JSON object
    availability_status = Column(String, default="available")  # e.g., "available", "busy", "offline"
    timezone = Column(String, nullable=True)
    preferred_language = Column(String, default="en")
    is_email_verified = Column(Boolean, default=False)
    is_phone_verified = Column(Boolean, default=False)
    verification_badge = Column(String, nullable=True)  # e.g., "verified", "trusted"
    profile_visibility = Column(String, default="public")  # e.g., "public", "private", "connections_only"
    show_email = Column(Boolean, default=True)
    show_phone = Column(Boolean, default=True)
    last_active_at = Column(DateTime, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())

    user = relationship("User", back_populates="profile")


class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    recipient_id = Column(Integer, ForeignKey("users.id"), index=True)
    sender_id = Column(Integer, ForeignKey("users.id"), nullable=True)
    type = Column(String, index=True)  # e.g., "message", "task_assigned", "sprint_update"
    message = Column(String)
    payload = Column(JSON, nullable=True)  # Additional data related to the notification
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

    recipient = relationship("User", foreign_keys=[recipient_id], back_populates="notifications_received")
    sender = relationship("User", foreign_keys=[sender_id], back_populates="notifications_sent")

# Add relationships to User model
User.notifications_received = relationship("Notification", foreign_keys=[Notification.recipient_id], back_populates="recipient")
User.notifications_sent = relationship("Notification", foreign_keys=[Notification.sender_id], back_populates="sender")
