#!/usr/bin/env python3
"""Test script for sorting and limiting functionality."""

import sys
import os

# Add the source directory to path
sys.path.insert(0, '/xfiles/upd2/mr_kg/src/mr_kg')

# Import modules directly
from graph_store import KnowledgeGraphStore
from embeddings import EmbeddingManager
from query.query_parsers import QueryParser
from query.query_compilers import QueryCompiler
from query.result_formatters import ResultFormatter

def test_sorting_and_limiting():
    """Test the new sorting and limiting functionality."""
    print("Testing sorting and limiting functionality...")
    
    # Initialize components
    storage_path = os.path.expanduser("~/.mr_kg_data")
    cache_dir = os.path.expanduser("~/.mr_kg_cache")
    
    graph_store = KnowledgeGraphStore(storage_path)
    embedding_manager = EmbeddingManager(cache_dir=cache_dir)
    
    # Create components manually
    parser = QueryParser()
    compiler = QueryCompiler(graph_store, embedding_manager)
    formatter = ResultFormatter(graph_store)
    
    print(f"Graph has {graph_store.graph.number_of_nodes()} nodes and {graph_store.graph.number_of_edges()} edges")
    
    # Test 1: Simple sorting by name
    test_query_1 = """find_people_sorted:
  find:
    nodes:
      type: Person
    order_by: name
    order: asc
    limit: 5
    return: ['name', 'description']"""
    
    print("\n" + "="*50)
    print("Test 1: Simple sorting by name (ascending, limit 5)")
    
    try:
        parsed = parser.parse_yaml_query(test_query_1)
        compiled_query = compiler.compile_query(parsed)
        results = compiled_query()
        
        print(f"Results: {len(results)} items")
        for item in results:
            print(f"  - {item['name']} ({item.get('type', 'Unknown')})")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    
    # Test 2: Advanced multi-field sorting
    test_query_2 = """find_people_advanced_sort:
  find:
    nodes:
      type: Person
    order_by:
      - field: created_at
        direction: desc
      - field: name
        direction: asc
    limit: 3
    return: ['name', 'description', 'created_at']"""
    
    print("\n" + "="*50)
    print("Test 2: Advanced multi-field sorting (created_at desc, name asc, limit 3)")
    
    try:
        parsed2 = parser.parse_yaml_query(test_query_2)
        compiled_query2 = compiler.compile_query(parsed2)
        results2 = compiled_query2()
        
        print(f"Results: {len(results2)} items")
        for item in results2:
            print(f"  - {item['name']} (created: {item.get('created_at', 'N/A')})")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    
    # Test 3: Connectivity query with sorting
    test_query_3 = """find_eric_sorted:
  find:
    nodes:
      type: Person
      name: "Eric Livesay"
    relations:
      - sent
      - mentions
    depth: 1
    order_by: name
    order: desc
    limit: 5
    return: ['name', 'type', 'description']"""
    
    print("\n" + "="*50)
    print("Test 3: Connectivity query with sorting (Eric's connections, name desc, limit 5)")
    
    try:
        parsed3 = parser.parse_yaml_query(test_query_3)
        compiled_query3 = compiler.compile_query(parsed3)
        results3 = compiled_query3()
        
        if isinstance(results3, dict) and 'nodes' in results3:
            print(f"Starting nodes: {results3.get('starting_nodes', [])}")
            print(f"Total nodes: {results3.get('node_count', 0)}")
            print(f"Nodes (sorted):")
            for node in results3.get('nodes', []):
                print(f"  - {node['name']} ({node.get('type', 'Unknown')})")
        else:
            print(f"Results: {len(results3) if isinstance(results3, list) else 1} items")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    
    # Test 4: No sorting, just limiting
    test_query_4 = """find_any_entities:
  find:
    nodes:
      type: Person
    limit: 3
    return: ['name', 'type']"""
    
    print("\n" + "="*50)
    print("Test 4: No sorting, just limiting (first 3 Person entities)")
    
    try:
        parsed4 = parser.parse_yaml_query(test_query_4)
        compiled_query4 = compiler.compile_query(parsed4)
        results4 = compiled_query4()
        
        print(f"Results: {len(results4)} items")
        for item in results4:
            print(f"  - {item['name']} ({item.get('type', 'Unknown')})")
            
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()

if __name__ == "__main__":
    test_sorting_and_limiting()
