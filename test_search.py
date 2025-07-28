#!/usr/bin/env python3
"""Test script to directly test the search functionality."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'kg'))

from kg.graph_commands import kg_search
import asyncio

async def test_search():
    """Test the search functionality directly."""
    
    print("🔍 Testing search functionality...")
    
    # Test semantic search for "John Smith"
    print("\n1. Testing semantic search for 'John Smith':")
    result = await kg_search(
        query="John Smith",
        limit=10,
        semantic=True,
        threshold=0.7
    )
    
    print(f"Semantic search result: {result}")
    
    if result.get('success'):
        print(f"✅ Semantic search successful!")
        print(f"Found {len(result.get('results', []))} results:")
        for i, res in enumerate(result.get('results', [])):
            print(f"  {i+1}. {res.get('entity', 'Unknown')} ({res.get('type', 'Unknown')}) - Score: {res.get('score', 0.0)}")
    else:
        print(f"❌ Semantic search failed: {result.get('error', 'Unknown error')}")
    
    # Test text-based search for "John Smith"
    print("\n2. Testing text-based search for 'John Smith':")
    result2 = await kg_search(
        query="John Smith",
        limit=10,
        semantic=False,
        threshold=0.7
    )
    
    print(f"Text search result: {result2}")
    
    if result2.get('success'):
        print(f"✅ Text search successful!")
        print(f"Found {len(result2.get('results', []))} results:")
        for i, res in enumerate(result2.get('results', [])):
            print(f"  {i+1}. {res.get('entity', 'Unknown')} ({res.get('type', 'Unknown')}) - Score: {res.get('score', 0.0)}")
    else:
        print(f"❌ Text search failed: {result2.get('error', 'Unknown error')}")
    
    # Test text-based search for "Google"
    print("\n3. Testing text-based search for 'Google':")
    result3 = await kg_search(
        query="Google",
        limit=10,
        semantic=False,
        threshold=0.7
    )
    
    print(f"Text search result: {result3}")
    
    if result3.get('success'):
        print(f"✅ Text search successful!")
        print(f"Found {len(result3.get('results', []))} results:")
        for i, res in enumerate(result3.get('results', [])):
            print(f"  {i+1}. {res.get('entity', 'Unknown')} ({res.get('type', 'Unknown')}) - Score: {res.get('score', 0.0)}")
    else:
        print(f"❌ Text search failed: {result3.get('error', 'Unknown error')}")

if __name__ == "__main__":
    asyncio.run(test_search()) 