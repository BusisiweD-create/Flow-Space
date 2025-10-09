import requests
import json

def test_analytics_health():
    """Test the public analytics health endpoint"""
    url = "http://localhost:8000/api/v1/analytics/health/public"
    
    try:
        response = requests.get(url)
        print(f"Status Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("Response:")
            print(json.dumps(data, indent=2))
            
            # Check if we're getting the expected flat structure
            if data.get("total_sprints") is not None:
                print("✅ SUCCESS: Backend is returning flat structure as expected!")
                print(f"   - Total Sprints: {data.get('total_sprints', 0)}")
                print(f"   - Total Deliverables: {data.get('total_deliverables', 0)}")
                print(f"   - Total Users: {data.get('total_users', 0)}")
            else:
                print("❌ ERROR: Backend is not returning expected flat structure")
        else:
            print(f"❌ ERROR: Request failed with status {response.status_code}")
            print(f"Response: {response.text}")
            
    except requests.exceptions.ConnectionError:
        print("❌ ERROR: Could not connect to backend server. Make sure it's running on port 8000.")
    except Exception as e:
        print(f"❌ ERROR: {e}")

if __name__ == "__main__":
    test_analytics_health()