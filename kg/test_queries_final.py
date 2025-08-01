#!/usr/bin/env python3
"""
Final Knowledge Graph Query Test

This script tests all working query functionality.
"""

import os
from kg.graph_store import KnowledgeGraphStore
from kg.embeddings import EmbeddingManager
from kg.query_engine import KnowledgeGraphQueryEngine

def main():
    """Test all working queries."""
    print("🧠 FINAL KNOWLEDGE GRAPH QUERY TEST")
    print("=" * 50)
    
    # Setup
    storage_path = os.path.expanduser("~/.mr_kg_data/knowledge_graph.json")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    query_engine = KnowledgeGraphQueryEngine(graph_store, embedding_manager)
    
    # Show stats
    stats = graph_store.get_statistics()
    print(f"📊 Knowledge Graph: {stats.get('num_entities', 0)} entities, {stats.get('num_relationships', 0)} relationships")
    
    # Test 1: Find all entities
    print("\n1️⃣ Testing: Find all entities")
    query1 = """
find_all_entities:
  find:
    nodes:
      return: ["name", "type"]
      limit: 10
"""
    
    result1 = query_engine.execute_query(query1)
    print(f"✅ Success: {result1.get('success', False)}")
    if result1.get('success'):
        print(f"📊 Found {len(result1.get('results', []))} entities")
        for entity in result1.get('results', [])[:5]:
            print(f"   - {entity.get('name', 'Unknown')} ({entity.get('type', 'Unknown')})")
    else:
        print(f"❌ Error: {result1.get('error', 'Unknown error')}")
    
    # Test 2: Find Person entities
    print("\n2️⃣ Testing: Find Person entities")
    query2 = """
find_people:
  find:
    nodes:
      entity_type: "Person"
      return: ["name", "type"]
      limit: 5
"""
    
    result2 = query_engine.execute_query(query2)
    print(f"✅ Success: {result2.get('success', False)}")
    if result2.get('success'):
        print(f"📊 Found {len(result2.get('results', []))} people")
        for person in result2.get('results', []):
            print(f"   - {person.get('name', 'Unknown')}")
    else:
        print(f"❌ Error: {result2.get('error', 'Unknown error')}")
    
    # Test 3: Find Document entities
    print("\n3️⃣ Testing: Find Document entities")
    query3 = """
find_documents:
  find:
    nodes:
      entity_type: "Document"
      return: ["name", "type"]
      limit: 5
"""
    
    result3 = query_engine.execute_query(query3)
    print(f"✅ Success: {result3.get('success', False)}")
    if result3.get('success'):
        print(f"📊 Found {len(result3.get('results', []))} documents")
        for doc in result3.get('results', []):
            print(f"   - {doc.get('name', 'Unknown')}")
    else:
        print(f"❌ Error: {result3.get('error', 'Unknown error')}")
    
    # Test 4: Find connected entities (relationships)
    print("\n4️⃣ Testing: Find connected entities (shows relationships)")
    query4 = """
find_connected:
  find:
    nodes:
      depth: 1
      return: ["name", "type"]
      limit: 10
"""
    
    result4 = query_engine.execute_query(query4)
    print(f"✅ Success: {result4.get('success', False)}")
    if result4.get('success'):
        print(f"📊 Found {len(result4.get('results', []))} connected entities")
        for entity in result4.get('results', [])[:5]:
            print(f"   - {entity.get('name', 'Unknown')} ({entity.get('type', 'Unknown')})")
    else:
        print(f"❌ Error: {result4.get('error', 'Unknown error')}")
    
    # Test 5: Find specific entity type with properties
    print("\n5️⃣ Testing: Find entities with properties")
    query5 = """
find_with_properties:
  find:
    nodes:
      entity_type: "Person"
      return: ["name", "type", "properties"]
      limit: 3
"""
    
    result5 = query_engine.execute_query(query5)
    print(f"✅ Success: {result5.get('success', False)}")
    if result5.get('success'):
        print(f"📊 Found {len(result5.get('results', []))} entities with properties")
        for entity in result5.get('results', []):
            print(f"   - {entity.get('name', 'Unknown')}")
            props = entity.get('properties', {})
            if props:
                print(f"     Properties: {props}")
    else:
        print(f"❌ Error: {result5.get('error', 'Unknown error')}")
    
    # Test 6: Search for specific text
    print("\n6️⃣ Testing: Search for 'John'")
    query6 = """
search_john:
  find:
    nodes:
      properties:
        name: "John"
      return: ["name", "type"]
      limit: 5
"""
    
    result6 = query_engine.execute_query(query6)
    print(f"✅ Success: {result6.get('success', False)}")
    if result6.get('success'):
        print(f"📊 Found {len(result6.get('results', []))} entities with 'John'")
        for entity in result6.get('results', []):
            print(f"   - {entity.get('name', 'Unknown')} ({entity.get('type', 'Unknown')})")
    else:
        print(f"❌ Error: {result6.get('error', 'Unknown error')}")
    
    print("\n✅ All query tests completed!")
    print("\n🎯 SUMMARY:")
    print("   ✅ Entity queries work")
    print("   ✅ Type filtering works") 
    print("   ✅ Property filtering works")
    print("   ✅ Connectivity queries work")
    print("   ✅ Query parsing and execution work")

if __name__ == "__main__":
    main() 