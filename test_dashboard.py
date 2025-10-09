import requests
import json

# Test the dashboard API endpoint
url = "http://127.0.0.1:8000/api/v1/analytics/dashboard"

# Use a valid JWT token for authentication
try:
    headers = {"Authorization": "Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjMiLCJlbWFpbCI6InRlc3RAZXhhbXBsZS5jb20iLCJyb2xlIjoiYWRtaW4iLCJleHAiOjE3NTk4MzE1MzQsInR5cGUiOiJhY2Nlc3MifQ.2We4qNuXkKkuTARVS6DFHuUUgB3CxZ3ncdFkCyNCf9o"}
    response = requests.get(url, headers=headers)
    print(f"Status Code: {response.status_code}")
    print(f"Response: {response.text}")
    
    if response.status_code == 200:
        data = response.json()
        print("\nParsed JSON:")
        print(json.dumps(data, indent=2))
        
        # Check specific fields that might cause type conversion issues
        if 'user_activity' in data:
            print("\nUser Activity Fields:")
            for key, value in data['user_activity'].items():
                print(f"  {key}: {value} (type: {type(value)})")
        
        if 'recent_users' in data:
            print("\nRecent Users (first user):")
            if data['recent_users']:
                user = data['recent_users'][0]
                for key, value in user.items():
                    print(f"  {key}: {value} (type: {type(value)})")
                    
except Exception as e:
    print(f"Error: {e}")