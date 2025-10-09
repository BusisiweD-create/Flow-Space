#!/usr/bin/env python3
"""
Test script to verify authentication flow and clear any stored tokens
"""

import requests
import json
import os
from pathlib import Path

def clear_stored_tokens():
    """Clear any stored authentication tokens from the frontend"""
    try:
        # Path to Flutter's shared preferences (where tokens might be stored)
        flutter_prefs_path = Path("c:/Flow/frontend/build")
        
        # This is where Flutter web stores local storage data
        # In a real scenario, we'd need to clear browser local storage
        print("ℹ️  To clear stored authentication tokens:")
        print("1. Open Chrome Developer Tools (F12)")
        print("2. Go to Application tab")
        print("3. Clear Local Storage and Session Storage")
        print("4. Refresh the page")
        
    except Exception as e:
        print(f"⚠️  Error clearing tokens: {e}")

def test_authentication():
    """Test the authentication endpoints"""
    base_url = "http://127.0.0.1:8000"
    
    # Test user credentials
    test_user = {
        "email": "testuser@example.com",
        "password": "TestPassword123!",
        "first_name": "Test",
        "last_name": "User"
    }
    
    try:
        # Test health check
        print("🧪 Testing backend health...")
        health_response = requests.get(f"{base_url}/health", timeout=10)
        print(f"✅ Health check: {health_response.status_code}")
        if health_response.status_code == 200:
            print(f"✅ Health response: {health_response.json()}")
        
        # Test registration
        print("\n🧪 Testing user registration...")
        register_response = requests.post(
            f"{base_url}/api/v1/auth/register",
            json=test_user,
            timeout=10
        )
        print(f"✅ Registration: {register_response.status_code}")
        if register_response.status_code == 200:
            print(f"✅ Registration response: {register_response.json()}")
        elif register_response.status_code == 400:
            print("ℹ️  User already exists, proceeding with login...")
        else:
            print(f"❌ Registration error: {register_response.text}")
        
        # Test login using OAuth2 form data (username/password)
        print("\n🧪 Testing user login...")
        login_data = {
            "username": test_user["email"],
            "password": test_user["password"]
        }
        login_response = requests.post(
            f"{base_url}/api/v1/auth/login",
            data=login_data,
            timeout=10
        )
        print(f"✅ Login: {login_response.status_code}")
        
        if login_response.status_code == 200:
            login_data = login_response.json()
            access_token = login_data.get("access_token")
            
            if access_token:
                print(f"✅ Access token obtained: {access_token[:50]}...")
                
                # Test dashboard access with valid token
                print("\n🧪 Testing dashboard access...")
                headers = {"Authorization": f"Bearer {access_token}"}
                dashboard_response = requests.get(
                    f"{base_url}/api/v1/analytics/dashboard",
                    headers=headers,
                    timeout=10
                )
                print(f"✅ Dashboard: {dashboard_response.status_code}")
                
                if dashboard_response.status_code == 200:
                    print("🎉 Authentication flow successful!")
                    print("\n🔑 Use these credentials in the frontend:")
                    print(f"Email: {test_user['email']}")
                    print(f"Password: {test_user['password']}")
                else:
                    print(f"❌ Dashboard error: {dashboard_response.text}")
            else:
                print("❌ No access token in login response")
        else:
            print(f"❌ Login failed: {login_response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ Cannot connect to backend. Make sure it's running on http://127.0.0.1:8000")
    except Exception as e:
        print(f"❌ Error during authentication test: {e}")

if __name__ == "__main__":
    print("🔍 Testing Authentication Flow")
    print("=" * 50)
    
    # Clear any stored tokens that might be causing issues
    clear_stored_tokens()
    print()
    
    # Test the authentication endpoints
    test_authentication()
    
    print("\n" + "=" * 50)
    print("💡 If you're getting 'missing or invalid authentication code':")
    print("1. Clear browser local storage (F12 → Application tab)")
    print("2. Make sure backend is running on http://127.0.0.1:8000")
    print("3. Use the test credentials above to login again")