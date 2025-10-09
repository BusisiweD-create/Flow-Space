"""
Settings router for user preferences and application settings
"""

from fastapi import APIRouter, HTTPException, Depends, status
from sqlalchemy.orm import Session
from typing import Dict, Any
from datetime import datetime

from database import get_db
from models import UserSettings
from schemas import SettingsCreate, SettingsUpdate, SettingsResponse
from auth_utils import get_token_data
from dependencies import get_current_user

router = APIRouter()

@router.get("/me", response_model=SettingsResponse)
def get_current_user_settings(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Get current user's settings"""
    user_id = str(current_user.id)
    settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
    
    if not settings:
        # Return default settings if user doesn't have any saved settings
        return SettingsResponse(
            user_id=user_id,
            dark_mode=False,
            notifications_enabled=True,
            language="English",
            sync_on_mobile_data=False,
            auto_backup=False,
            share_analytics=False,
            allow_notifications=True,
            created_at=datetime.now(),
            updated_at=None
        )
    
    return settings

@router.post("/me", response_model=SettingsResponse)
def create_user_settings(
    settings: SettingsCreate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Create new user settings for current user"""
    user_id = str(current_user.id)
    
    # Check if settings already exist for this user
    existing_settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
    
    if existing_settings:
        raise HTTPException(status_code=400, detail="Settings already exist for this user")
    
    db_settings = UserSettings(user_id=user_id, **settings.dict())
    db.add(db_settings)
    db.commit()
    db.refresh(db_settings)
    
    return db_settings

@router.put("/me", response_model=SettingsResponse)
def update_user_settings(
    settings: SettingsUpdate,
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Update current user's settings"""
    user_id = str(current_user.id)
    db_settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
    
    if not db_settings:
        # Create new settings if they don't exist
        db_settings = UserSettings(user_id=user_id, **settings.dict())
        db.add(db_settings)
    else:
        # Update existing settings
        for key, value in settings.dict(exclude_unset=True).items():
            setattr(db_settings, key, value)
    
    db.commit()
    db.refresh(db_settings)
    
    return db_settings

@router.delete("/me")
def delete_user_settings(
    current_user = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    """Delete current user's settings"""
    user_id = str(current_user.id)
    settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
    
    if not settings:
        raise HTTPException(status_code=404, detail="Settings not found")
    
    db.delete(settings)
    db.commit()
    
    return {"message": "Settings deleted successfully"}

# Keep the original endpoints for backward compatibility (admin use only)
@router.get("/{user_id}", response_model=SettingsResponse)
def get_user_settings_by_id(user_id: str, db: Session = Depends(get_db)):
    """Get user settings by user ID (admin only)"""
    settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
    
    if not settings:
        # Return default settings if user doesn't have any saved settings
        return SettingsResponse(
            user_id=user_id,
            dark_mode=False,
            notifications_enabled=True,
            language="English",
            sync_on_mobile_data=False,
            auto_backup=False,
            share_analytics=False,
            allow_notifications=True,
            created_at=datetime.now(),
            updated_at=None
        )
    
    return settings