"""
Profile router for user profile management
"""

from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional, List
import os
from datetime import datetime

from database import get_db
from models import UserProfile
from schemas import UserProfileCreate, UserProfileUpdate, UserProfile
from crud import (
    get_user_profile, create_user_profile, update_user_profile,
    delete_user_profile, get_user_profiles, get_user_profile_by_email
)
from services.file_upload_service import file_upload_service
from schemas import FileUploadResponse

router = APIRouter()

@router.get("/", response_model=List[UserProfile])
def get_all_profiles(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """Get all user profiles"""
    return get_user_profiles(db, skip=skip, limit=limit)

@router.get("/{user_id}", response_model=UserProfile)
def get_profile(user_id: str, db: Session = Depends(get_db)):
    """Get user profile by user ID"""
    profile = get_user_profile(db, user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile

@router.post("/", response_model=UserProfile)
def create_profile(profile: UserProfileCreate, db: Session = Depends(get_db)):
    """Create a new user profile"""
    # Check if profile already exists
    existing_profile = get_user_profile(db, profile.user_id)
    if existing_profile:
        raise HTTPException(status_code=400, detail="Profile already exists for this user")
    
    # Check if email is already taken
    existing_email = get_user_profile_by_email(db, profile.email)
    if existing_email:
        raise HTTPException(status_code=400, detail="Email already registered")
    
    return create_user_profile(db, profile)

@router.put("/{user_id}", response_model=UserProfile)
def update_profile(user_id: str, profile: UserProfileUpdate, db: Session = Depends(get_db)):
    """Update user profile"""
    updated_profile = update_user_profile(db, user_id, profile)
    if not updated_profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return updated_profile

@router.delete("/{user_id}")
def delete_profile(user_id: str, db: Session = Depends(get_db)):
    """Delete user profile"""
    if not delete_user_profile(db, user_id):
        raise HTTPException(status_code=404, detail="Profile not found")
    return {"message": "Profile deleted successfully"}

@router.post("/{user_id}/upload-picture", response_model=FileUploadResponse)
async def upload_profile_picture(
    user_id: str,
    file: UploadFile = File(...),
    db: Session = Depends(get_db)
):
    """Upload profile picture for user"""
    # Check if user exists
    profile = get_user_profile(db, user_id)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    
    try:
        # Upload file using the file upload service
        upload_result = await file_upload_service.upload_file(file, prefix=f"profile_pictures/{user_id}")
        
        # Update profile with picture URL
        update_data = UserProfileUpdate(profile_picture=upload_result["url"])
        update_user_profile(db, user_id, update_data)
        
        return upload_result
    
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading file: {str(e)}")

@router.get("/email/{email}", response_model=UserProfile)
def get_profile_by_email(email: str, db: Session = Depends(get_db)):
    """Get user profile by email"""
    profile = get_user_profile_by_email(db, email)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile