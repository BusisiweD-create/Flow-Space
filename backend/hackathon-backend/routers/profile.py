"""
Profile router for user profile management
"""

from fastapi import APIRouter, HTTPException, Depends, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import Optional, List
import shutil
import os
from datetime import datetime

from database import get_db
from models import UserProfile
from schemas import UserProfileCreate, UserProfileUpdate, UserProfile
from crud import (
    get_user_profile, create_user_profile, update_user_profile,
    delete_user_profile, get_user_profiles, get_user_profile_by_email
)

router = APIRouter()

# Configure upload directory
UPLOAD_DIR = "uploads/profile_pictures"
os.makedirs(UPLOAD_DIR, exist_ok=True)

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

@router.post("/{user_id}/upload-picture")
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
    
    # Validate file type
    if not file.content_type.startswith('image/'):
        raise HTTPException(status_code=400, detail="Only image files are allowed")
    
    # Generate unique filename
    file_extension = os.path.splitext(file.filename)[1]
    filename = f"{user_id}_{int(datetime.now().timestamp())}{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)
    
    try:
        # Save the file
        with open(file_path, "wb") as buffer:
            shutil.copyfileobj(file.file, buffer)
        
        # Update profile with picture URL
        picture_url = f"/{file_path}"
        update_data = UserProfileUpdate(profile_picture=picture_url)
        update_user_profile(db, user_id, update_data)
        
        return {"message": "Profile picture uploaded successfully", "picture_url": picture_url}
    
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error uploading file: {str(e)}")

@router.get("/email/{email}", response_model=UserProfile)
def get_profile_by_email(email: str, db: Session = Depends(get_db)):
    """Get user profile by email"""
    profile = get_user_profile_by_email(db, email)
    if not profile:
        raise HTTPException(status_code=404, detail="Profile not found")
    return profile