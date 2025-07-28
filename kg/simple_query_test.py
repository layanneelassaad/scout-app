#!/usr/bin/env python3
"""
Simple Knowledge Graph Query Test

This script tests basic queries with the correct YAML format.
"""

import os
from graph_store import KnowledgeGraphStore
from embeddings import EmbeddingManager
from query_engine import KnowledgeGraphQueryEngine

def main():
    """Test basic queries."""
    print("🧠 SIMPLE KNOWLEDGE GRAPH QUERY TEST")
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
    
    # Test 4: Find relationships
    print("\n4️⃣ Testing: Find relationships")
    query4 = """
find_relationships:
  find:
    edges:
      return: ["source", "target", "relationship_type"]
      limit: 10
"""
    
    result4 = query_engine.execute_query(query4)
    print(f"✅ Success: {result4.get('success', False)}")
    if result4.get('success'):
        print(f"📊 Found {len(result4.get('results', []))} relationships")
        for rel in result4.get('results', [])[:5]:
            print(f"   - {rel.get('source', 'Unknown')} -> {rel.get('relationship_type', 'Unknown')} -> {rel.get('target', 'Unknown')}")
    else:
        print(f"❌ Error: {result4.get('error', 'Unknown error')}")
    
    print("\n✅ Query testing completed!")

if __name__ == "__main__":
    main() 