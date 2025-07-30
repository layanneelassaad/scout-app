#!/usr/bin/env python3
"""
Test script to verify the backend can start correctly
"""
import sys
import os

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

try:
    from kg import app
    print("✅ Backend imports successfully")
    
    # Test that the app has routes
    routes = [route.path for route in app.routes]
    print(f"✅ Found {len(routes)} routes")
    
    # Check for key routes
    key_routes = ['/', '/makesession/kg2', '/chat/{session_id}/events', '/chat/{session_id}/send']
    for route in key_routes:
        if any(route in r for r in routes):
            print(f"✅ Found route: {route}")
        else:
            print(f"⚠️  Missing route: {route}")
            
    print("✅ Backend test completed successfully")
    
except Exception as e:
    print(f"❌ Backend test failed: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1) 