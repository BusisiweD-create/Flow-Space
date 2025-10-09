#!/usr/bin/env python3
"""
Script to generate a valid JWT token for testing the analytics API
"""

import sys
import os

# Add the backend directory to Python path
sys.path.insert(0, 'c:\\Flow\\backend\\hackathon-backend')

from auth_utils import create_access_token
from datetime import timedelta

# Generate a test token with user data
def generate_test_token():
    # Test user data
    user_data = {
        "sub": "123",  # User ID
        "email": "test@example.com",
        "role": "admin"
    }
    
    # Create access token with 1 hour expiration
    token = create_access_token(user_data, expires_delta=timedelta(hours=1))
    return token

if __name__ == "__main__":
    token = generate_test_token()
    print(f"Generated JWT Token:")
    print(token)
    print(f"\nUse this in your Authorization header:")
    print(f"Authorization: Bearer {token}")