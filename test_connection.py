#!/usr/bin/env python3
"""
Test script to verify the Swift app can connect to the backend.
This simulates what the Swift app does.
"""

import requests
import json
import time

def test_swift_app_connection():
    """Test the connection flow that the Swift app uses."""
    
    base_url = "http://localhost:8020"
    api_key = "3d453a5f-1bd8-4d92-b8b8-f4bae99ccda4"
    
    print("Testing Swift app connection to backend...")
    
    # Step 1: Create a session (like Swift app does)
    print("1. Creating session...")
    session_response = requests.get(f"{base_url}/makesession/kg2?api_key={api_key}")
    
    if session_response.status_code != 200:
        print(f"❌ Failed to create session: {session_response.status_code}")
        return False
    
    session_data = session_response.json()
    session_id = session_data['log_id']
    print(f"✅ Session created: {session_id}")
    
    # Step 2: Send a search query (like Swift app does)
    print("2. Sending search query...")
    search_data = [{"type": "text", "text": "test search query"}]
    search_response = requests.post(
        f"{base_url}/chat/{session_id}/send?api_key={api_key}",
        headers={"Content-Type": "application/json"},
        data=json.dumps(search_data)
    )
    
    if search_response.status_code != 200:
        print(f"❌ Failed to send search query: {search_response.status_code}")
        return False
    
    print("✅ Search query sent successfully")
    
    # Step 3: Test SSE connection (simulate what Swift app does)
    print("3. Testing SSE connection...")
    try:
        sse_response = requests.get(
            f"{base_url}/chat/{session_id}/events?api_key={api_key}",
            stream=True,
            timeout=10
        )
        
        if sse_response.status_code != 200:
            print(f"❌ Failed to connect to SSE: {sse_response.status_code}")
            return False
        
        print("✅ SSE connection established")
        
        # Read a few events to verify they're coming through
        event_count = 0
        for line in sse_response.iter_lines():
            if line:
                line_str = line.decode('utf-8')
                if line_str.startswith('data:'):
                    print(f"   📡 Received event: {line_str}")
                    event_count += 1
                    if event_count >= 3:  # Just read a few events
                        break
        
        print(f"✅ Received {event_count} events successfully")
        
    except Exception as e:
        print(f"❌ SSE connection failed: {e}")
        return False
    
    print("\n🎉 All tests passed! The Swift app should be able to connect successfully.")
    return True

if __name__ == "__main__":
    test_swift_app_connection() 