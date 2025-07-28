#!/usr/bin/env python3
"""Test script to verify YAML query functionality with comparison operators."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

from query_engine import KnowledgeGraphQueryEngine
from graph_store import KnowledgeGraphStore
from embeddings import EmbeddingManager

def create_test_data(graph_store):
    """Create some test data with dates and file extensions."""
    # Add some test entities with different properties
    test_entities = [
        {
            'name': 'file1.py',
            'type': 'file',
            'file_extension': '.py',
            'created_date': '2025-07-11',
            'size': 1024
        },
        {
            'name': 'file2.py', 
            'type': 'file',
            'file_extension': '.py',
            'created_date': '2025-07-12',
            'size': 2048
        },
        {
            'name': 'file3.txt',
            'type': 'file', 
            'file_extension': '.txt',
            'created_date': '2025-07-09',
            'size': 512
        },
        {
            'name': 'file4.js',
            'type': 'file',
            'file_extension': '.js', 
            'created_date': '2025-07-13',
            'size': 1536
        }
    ]
    
    for entity in test_entities:
        graph_store.add_entity(
            entity['name'],
            entity_type=entity['type'],
            properties=entity
        )
    
    print(f"Added {len(test_entities)} test entities")

def test_direct_property_matching(query_engine):
    """Test direct property matching (should work)."""
    print("\n=== Testing Direct Property Matching ===")
    
    query_yaml = """
test_direct_properties:
  find:
    nodes:
      properties:
        file_extension: ".py"
      return: ["name", "file_extension", "created_date"]
"""
    
    result = query_engine.execute_query(query_yaml)
    print(f"Query success: {result['success']}")
    if result['success']:
        print(f"Found {result['result_count']} results:")
        for r in result['results']:
            print(f"  - {r}")
    else:
        print(f"Error: {result['error']}")

def test_comparison_operators(query_engine):
    """Test comparison operators (the fix we implemented)."""
    print("\n=== Testing Comparison Operators (FIXED) ===")
    
    query_yaml = """
test_date_comparison:
  find:
    nodes:
      properties:
        created_date:
          gt: "2025-07-10"
      return: ["name", "file_extension", "created_date"]
"""
    
    result = query_engine.execute_query(query_yaml)
    print(f"Query success: {result['success']}")
    if result['success']:
        print(f"Found {result['result_count']} results:")
        for r in result['results']:
            print(f"  - {r}")
    else:
        print(f"Error: {result['error']}")

def test_multiple_conditions(query_engine):
    """Test multiple conditions in properties."""
    print("\n=== Testing Multiple Conditions ===")
    
    query_yaml = """
test_multiple_conditions:
  find:
    nodes:
      properties:
        file_extension: ".py"
        size:
          gt: 1500
      return: ["name", "file_extension", "size", "created_date"]
"""
    
    result = query_engine.execute_query(query_yaml)
    print(f"Query success: {result['success']}")
    if result['success']:
        print(f"Found {result['result_count']} results:")
        for r in result['results']:
            print(f"  - {r}")
    else:
        print(f"Error: {result['error']}")

def main():
    """Run the tests."""
    print("Testing YAML Query Engine with Comparison Operators")
    print("====================================================")
    
    # Initialize components
    graph_store = KnowledgeGraphStore(storage_path="/tmp/test_kg_graph.json")
    embedding_manager = EmbeddingManager(cache_dir="/tmp/test_kg_cache")  # This might need proper initialization
    query_engine = KnowledgeGraphQueryEngine(graph_store, embedding_manager)
    
    # Create test data
    create_test_data(graph_store)
    
    # Run tests
    test_direct_property_matching(query_engine)
    test_comparison_operators(query_engine)
    test_multiple_conditions(query_engine)
    
    print("\n=== Test Summary ===")
    print("If the comparison operators test shows results, the fix is working!")
    print("Expected: file1.py and file2.py should be returned (created after 2025-07-10)")

if __name__ == "__main__":
    main()
