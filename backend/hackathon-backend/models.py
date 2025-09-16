"""
SQLAlchemy database models
"""

from sqlalchemy import Column, Integer, String, DateTime, Boolean, Text, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

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
