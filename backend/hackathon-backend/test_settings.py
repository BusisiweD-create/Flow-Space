#!/usr/bin/env python3
"""
Test script to directly test settings functionality without FastAPI server
"""

import sys
from datetime import datetime
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from models import UserSettings
from schemas import SettingsResponse

# Database setup
SQLALCHEMY_DATABASE_URL = "sqlite:///./hackathon.db"
engine = create_engine(SQLALCHEMY_DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def test_settings_creation():
    """Test creating and retrieving user settings"""
    print("Testing settings functionality...")
    
    # Create a new session
    db = SessionLocal()
    
    try:
        # Test creating default settings for a user
        user_id = "test_user_123"
        
        # Check if user already has settings
        existing_settings = db.query(UserSettings).filter(UserSettings.user_id == user_id).first()
        
        if existing_settings:
            print(f"✓ User {user_id} already has settings:")
            print(f"  Dark mode: {existing_settings.dark_mode}")
            print(f"  Created at: {existing_settings.created_at}")
            
            # Convert to response schema
            response = SettingsResponse.from_orm(existing_settings)
            print(f"✓ SettingsResponse created successfully:")
            print(f"  User ID: {response.user_id}")
            print(f"  Dark mode: {response.dark_mode}")
            print(f"  Created at: {response.created_at}")
            print(f"  Updated at: {response.updated_at}")
            
        else:
            print(f"✗ User {user_id} has no settings")
            
            # Test creating default settings response
            default_response = SettingsResponse(
                user_id=user_id,
                dark_mode=False,
                created_at=datetime.now(),
                updated_at=None
            )
            print(f"✓ Default SettingsResponse created:")
            print(f"  User ID: {default_response.user_id}")
            print(f"  Dark mode: {default_response.dark_mode}")
            print(f"  Created at: {default_response.created_at}")
            print(f"  Updated at: {default_response.updated_at}")
            
    except Exception as e:
        print(f"✗ Error: {e}")
        import traceback
        traceback.print_exc()
    
    finally:
        db.close()

if __name__ == "__main__":
    test_settings_creation()