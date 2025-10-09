"""
SQLAlchemy database models
"""

from sqlalchemy import Column, Integer, String, Boolean, DateTime, ForeignKey, Text, Date, JSON, Table
from sqlalchemy.orm import relationship
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.sql import func
from datetime import datetime

Base = declarative_base()

# Association table for many-to-many relationship between deliverables and sprints
deliverable_sprints = Table(
    'deliverable_sprints',
    Base.metadata,
    Column('deliverable_id', Integer, ForeignKey('deliverables.id'), primary_key=True),
    Column('sprint_id', Integer, ForeignKey('sprints.id'), primary_key=True),
    Column('contribution_percentage', Integer, default=100),  # How much this sprint contributed
    Column('created_at', DateTime(timezone=True), server_default=func.now())
)

class Deliverable(Base):
    """Model for project deliverables with enhanced Use Case IV features"""
    __tablename__ = "deliverables"
    
    id = Column(Integer, primary_key=True, index=True)
    title = Column(String(255), nullable=False)
    description = Column(Text)
    definition_of_done = Column(Text)  # Definition of Done checklist
    status = Column(String(50), default="draft")  # draft, submitted, approved, change_requested
    priority = Column(String(50), default="medium")  # low, medium, high, critical
    due_date = Column(DateTime(timezone=True))
    created_by = Column(String(255))
    assigned_to = Column(String(255))
    
    # Evidence and artifacts
    evidence_links = Column(JSON)  # List of evidence URLs/links
    demo_link = Column(String(500))
    repo_link = Column(String(500))
    test_summary_link = Column(String(500))
    user_guide_link = Column(String(500))
    
    # Quality metrics
    test_pass_rate = Column(Integer)  # Percentage
    code_coverage = Column(Integer)  # Percentage
    escaped_defects = Column(Integer)
    defect_severity_mix = Column(JSON)  # {critical: 1, high: 2, medium: 3, low: 4}
    
    # Timestamps
    submitted_at = Column(DateTime(timezone=True))
    approved_at = Column(DateTime(timezone=True))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    
    # Relationships
    contributing_sprints = relationship("Sprint", 
                                      secondary="deliverable_sprints", 
                                      back_populates="deliverables",
                                      lazy="dynamic")
    signoffs = relationship("Signoff", 
                           primaryjoin="and_(Deliverable.id==Signoff.entity_id, Signoff.entity_type=='deliverable')",
                           foreign_keys="[Signoff.entity_id]",
                           viewonly=True,
                           back_populates="deliverable")
    audit_logs = relationship("AuditLog", 
                             primaryjoin="and_(Deliverable.id==AuditLog.entity_id, AuditLog.entity_type=='deliverable')",
                             foreign_keys="[AuditLog.entity_id]",
                             viewonly=True,
                             back_populates="deliverable")

class Sprint(Base):
    """Model for project sprints with comprehensive performance metrics"""
    __tablename__ = "sprints"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(255), nullable=False)
    description = Column(Text)
    
    # Sprint planning
    start_date = Column(DateTime(timezone=True))
    end_date = Column(DateTime(timezone=True))
    planned_points = Column(Integer, default=0)
    committed_points = Column(Integer, default=0)
    
    # Sprint outcomes
    completed_points = Column(Integer, default=0)
    carried_over_points = Column(Integer, default=0)
    added_during_sprint = Column(Integer, default=0)
    removed_during_sprint = Column(Integer, default=0)
    
    # Quality metrics
    test_pass_rate = Column(Integer)  # Percentage
    code_coverage = Column(Integer)  # Percentage
    escaped_defects = Column(Integer)
    defects_opened = Column(Integer)
    defects_closed = Column(Integer)
    defect_severity_mix = Column(JSON)  # {critical: 1, high: 2, medium: 3, low: 4}
    code_review_completion = Column(Integer)  # Percentage
    documentation_status = Column(String(50))  # complete, partial, missing
    
    # UAT and acceptance
    uat_notes = Column(Text)
    uat_pass_rate = Column(Integer)  # Percentage
    
    # Risk management
    risks_identified = Column(Integer)
    risks_mitigated = Column(Integer)
    blockers = Column(Text)
    decisions = Column(Text)
    
    status = Column(String(50), default="planning")  # planning, active, completed, reviewed
    created_by = Column(String(255))
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    updated_at = Column(DateTime(timezone=True), onupdate=func.now())
    reviewed_at = Column(DateTime(timezone=True))
    
    # Relationships
    deliverables = relationship("Deliverable", secondary="deliverable_sprints", back_populates="contributing_sprints")
    signoffs = relationship("Signoff", 
                           primaryjoin="and_(Sprint.id==Signoff.entity_id, Signoff.entity_type=='sprint')",
                           foreign_keys="[Signoff.entity_id]",
                           viewonly=True,
                           back_populates="sprint")
    audit_logs = relationship("AuditLog", 
                              primaryjoin="and_(Sprint.id==AuditLog.entity_id, AuditLog.entity_type=='sprint')",
                              foreign_keys="[AuditLog.entity_id]",
                              viewonly=True,
                              back_populates="sprint")

class Signoff(Base):
    """Model for comprehensive signoff workflow including deliverable approvals"""
    __tablename__ = "signoffs"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # Entity being signed off (sprint or deliverable)
    entity_type = Column(String(50), nullable=False)  # sprint, deliverable
    entity_id = Column(Integer, nullable=False)
    
    # Signer information
    signer_name = Column(String(255), nullable=False)
    signer_email = Column(String(255), nullable=False)
    signer_role = Column(String(100))  # client, product_owner, team_lead, etc.
    signer_company = Column(String(255))
    
    # Approval details
    decision = Column(String(50), default="pending")  # pending, approved, change_requested, rejected
    comments = Column(Text)
    change_request_details = Column(Text)
    
    # Digital signature metadata
    ip_address = Column(String(50))
    user_agent = Column(String(500))
    signature_hash = Column(String(500))  # For non-repudiation
    
    # Timestamps
    submitted_at = Column(DateTime(timezone=True), server_default=func.now())
    reviewed_at = Column(DateTime(timezone=True))
    responded_at = Column(DateTime(timezone=True))
    
    # Relationships - using viewonly since we're using entity_id/entity_type pattern
    deliverable = relationship("Deliverable", 
                             primaryjoin="and_(Signoff.entity_id==Deliverable.id, Signoff.entity_type=='deliverable')",
                             foreign_keys="[Signoff.entity_id]",
                             viewonly=True,
                             back_populates="signoffs")
    sprint = relationship("Sprint", 
                         primaryjoin="and_(Signoff.entity_id==Sprint.id, Signoff.entity_type=='sprint')",
                         foreign_keys="[Signoff.entity_id]",
                         viewonly=True,
                         back_populates="signoffs")
    
    # Audit logs relationship
    audit_logs = relationship("AuditLog", 
                            primaryjoin="and_(Signoff.id==AuditLog.entity_id, AuditLog.entity_type=='signoff')",
                            foreign_keys="[AuditLog.entity_id]",
                            viewonly=True,
                            back_populates="signoff")
    
    # Helper method to get the entity being signed off
    def get_entity(self):
        if self.entity_type == "deliverable":
            return self.deliverable
        elif self.entity_type == "sprint":
            return self.sprint
        return None

class AuditLog(Base):
    """Model for comprehensive audit trail tracking"""
    __tablename__ = "audit_logs"
    
    id = Column(Integer, primary_key=True, index=True)
    
    # User and session information
    user_id = Column(Integer, ForeignKey("users.id"))
    user_email = Column(String(255))
    user_role = Column(String(100))
    session_id = Column(String(500))
    ip_address = Column(String(50))
    user_agent = Column(String(500))
    
    # Action details
    action = Column(String(255), nullable=False)  # create, update, delete, approve, reject, view, etc.
    action_category = Column(String(100))  # deliverable, sprint, signoff, report, etc.
    
    # Entity information
    entity_type = Column(String(100))  # deliverable, sprint, signoff, user, etc.
    entity_id = Column(Integer)
    entity_name = Column(String(255))
    
    # Change tracking
    old_values = Column(JSON)
    new_values = Column(JSON)
    changed_fields = Column(JSON)
    
    # Context and metadata
    request_id = Column(String(500))
    endpoint = Column(String(500))
    http_method = Column(String(10))
    status_code = Column(Integer)
    
    # Timestamps
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # Relationships - using viewonly since we're using entity_id/entity_type pattern
    user = relationship("User", back_populates="audit_logs")
    deliverable = relationship("Deliverable", 
                             primaryjoin="and_(AuditLog.entity_id==Deliverable.id, AuditLog.entity_type=='deliverable')",
                             foreign_keys="[AuditLog.entity_id]",
                             viewonly=True,
                             back_populates="audit_logs")
    sprint = relationship("Sprint", 
                         primaryjoin="and_(AuditLog.entity_id==Sprint.id, AuditLog.entity_type=='sprint')",
                         foreign_keys="[AuditLog.entity_id]",
                         viewonly=True,
                         back_populates="audit_logs")
    signoff = relationship("Signoff", 
                          primaryjoin="and_(AuditLog.entity_id==Signoff.id, AuditLog.entity_type=='signoff')",
                          foreign_keys="[AuditLog.entity_id]",
                          viewonly=True,
                          back_populates="audit_logs")
    
    # Helper method to log changes
    @classmethod
    def log_change(cls, user, entity, action, old_values=None, new_values=None, **kwargs):
        """Helper method to create audit log entries for changes"""
        changed_fields = {}
        if old_values and new_values:
            for key in old_values.keys():
                if old_values.get(key) != new_values.get(key):
                    changed_fields[key] = {
                        'old': old_values.get(key),
                        'new': new_values.get(key)
                    }
        
        return cls(
            user_id=user.id if user else None,
            user_email=user.email if user else None,
            user_role=user.role if user else None,
            action=action,
            action_category=entity.__class__.__name__.lower(),
            entity_type=entity.__class__.__name__.lower(),
            entity_id=entity.id,
            entity_name=getattr(entity, 'name', getattr(entity, 'title', str(entity.id))),
            old_values=old_values,
            new_values=new_values,
            changed_fields=changed_fields,
            **kwargs
        )

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
    audit_logs = relationship("AuditLog", back_populates="user")

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
