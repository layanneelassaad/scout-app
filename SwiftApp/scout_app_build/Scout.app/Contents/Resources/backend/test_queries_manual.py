#!/usr/bin/env python3
"""
Manual Knowledge Graph Query Testing

This script allows you to manually test queries against your knowledge graph.
"""

import os
import sys
from graph_store import KnowledgeGraphStore
from embeddings import EmbeddingManager
from query_engine import KnowledgeGraphQueryEngine

def setup_query_engine():
    """Setup the query engine with your knowledge graph."""
    storage_path = os.path.expanduser("~/.mr_kg_data/knowledge_graph.json")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    query_engine = KnowledgeGraphQueryEngine(graph_store, embedding_manager)
    return query_engine, graph_store

def show_graph_stats(graph_store):
    """Show current knowledge graph statistics."""
    stats = graph_store.get_statistics()
    print(f"\n📊 Knowledge Graph Statistics:")
    print(f"   Entities: {stats.get('num_entities', 0)}")
    print(f"   Relationships: {stats.get('num_relationships', 0)}")
    
    # Show some sample entities by type
    print(f"\n📋 Sample Entities by Type:")
    entity_types = graph_store.get_all_entity_types()
    for entity_type in entity_types[:3]:  # Show first 3 types
        entities = graph_store.get_entities_by_type(entity_type)
        print(f"   {entity_type}: {len(entities)} entities")
        for i, (name, data) in enumerate(entities[:2]):  # Show first 2 of each type
            print(f"     - {name}")
        if len(entities) > 2:
            print(f"     ... and {len(entities) - 2} more")

def test_basic_queries(query_engine):
    """Test basic query functionality."""
    print("\n🧪 TESTING BASIC QUERIES")
    print("=" * 50)
    
    # Test 1: Find all entities
    print("\n1️⃣ Testing: Find all entities")
    query1 = """
    name: "Find All Entities"
    type: "entity_search"
    query:
      return: ["name", "type"]
      limit: 10
    """
    
    result1 = query_engine.execute_query(query1)
    print(f"✅ Success: {result1.get('success', False)}")
    if result1.get('success'):
        print(f"📊 Found {len(result1.get('results', []))} entities")
        for entity in result1.get('results', [])[:3]:  # Show first 3
            print(f"   - {entity.get('name', 'Unknown')} ({entity.get('type', 'Unknown')})")
    else:
        print(f"❌ Error: {result1.get('error', 'Unknown error')}")
    
    # Test 2: Find specific entity type
    print("\n2️⃣ Testing: Find all Person entities")
    query2 = """
    name: "Find People"
    type: "entity_search"
    query:
      entity_type: "Person"
      return: ["name", "type", "properties"]
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
    
    # Test 3: Find relationships
    print("\n3️⃣ Testing: Find relationships")
    query3 = """
    name: "Find Relationships"
    type: "relationship_search"
    query:
      return: ["source", "target", "relationship_type"]
      limit: 10
    """
    
    result3 = query_engine.execute_query(query3)
    print(f"✅ Success: {result3.get('success', False)}")
    if result3.get('success'):
        print(f"📊 Found {len(result3.get('results', []))} relationships")
        for rel in result3.get('results', [])[:5]:  # Show first 5
            print(f"   - {rel.get('source', 'Unknown')} -> {rel.get('relationship_type', 'Unknown')} -> {rel.get('target', 'Unknown')}")
    else:
        print(f"❌ Error: {result3.get('error', 'Unknown error')}")

def test_advanced_queries(query_engine):
    """Test advanced query functionality."""
    print("\n🔍 TESTING ADVANCED QUERIES")
    print("=" * 50)
    
    # Test 1: Property-based filtering
    print("\n1️⃣ Testing: Find entities with specific properties")
    query1 = """
    name: "Find Documents"
    type: "entity_search"
    query:
      entity_type: "Document"
      properties:
        file_extension: ".txt"
      return: ["name", "type", "properties"]
      limit: 5
    """
    
    result1 = query_engine.execute_query(query1)
    print(f"✅ Success: {result1.get('success', False)}")
    if result1.get('success'):
        print(f"📊 Found {len(result1.get('results', []))} .txt documents")
        for doc in result1.get('results', []):
            print(f"   - {doc.get('name', 'Unknown')}")
    else:
        print(f"❌ Error: {result1.get('error', 'Unknown error')}")
    
    # Test 2: Similarity search
    print("\n2️⃣ Testing: Similarity search")
    query2 = """
    name: "Similar to Developer"
    type: "similarity_search"
    query:
      query_text: "developer"
      k: 5
      return: ["name", "type", "similarity_score"]
    """
    
    result2 = query_engine.execute_query(query2)
    print(f"✅ Success: {result2.get('success', False)}")
    if result2.get('success'):
        print(f"📊 Found {len(result2.get('results', []))} similar entities")
        for entity in result2.get('results', []):
            print(f"   - {entity.get('name', 'Unknown')} (score: {entity.get('similarity_score', 0):.3f})")
    else:
        print(f"❌ Error: {result2.get('error', 'Unknown error')}")

def interactive_query(query_engine):
    """Allow interactive querying."""
    print("\n🎯 INTERACTIVE QUERY MODE")
    print("=" * 50)
    print("Enter your YAML query (type 'quit' to exit):")
    print("Example query:")
    print("""
    name: "My Query"
    type: "entity_search"
    query:
      entity_type: "Person"
      return: ["name", "type"]
      limit: 5
    """)
    
    while True:
        try:
            print("\n" + "="*50)
            query_yaml = input("Enter YAML query (or 'quit'): ")
            
            if query_yaml.lower() == 'quit':
                break
            
            if not query_yaml.strip():
                continue
            
            print("\n🔍 Executing query...")
            result = query_engine.execute_query(query_yaml)
            
            print(f"✅ Success: {result.get('success', False)}")
            if result.get('success'):
                print(f"📊 Results: {len(result.get('results', []))} found")
                print(f"⏱️  Execution time: {result.get('execution_time', 0):.3f}s")
                
                # Show results
                for i, item in enumerate(result.get('results', [])[:10]):  # Limit to 10
                    print(f"   {i+1}. {item}")
                
                if len(result.get('results', [])) > 10:
                    print(f"   ... and {len(result.get('results', [])) - 10} more results")
            else:
                print(f"❌ Error: {result.get('error', 'Unknown error')}")
                
        except KeyboardInterrupt:
            print("\n👋 Goodbye!")
            break
        except Exception as e:
            print(f"❌ Error: {e}")

def main():
    """Main function."""
    print("🧠 KNOWLEDGE GRAPH QUERY TESTING")
    print("=" * 60)
    
    # Setup query engine
    query_engine, graph_store = setup_query_engine()
    
    # Show current graph stats
    show_graph_stats(graph_store)
    
    # Test basic queries
    test_basic_queries(query_engine)
    
    # Test advanced queries
    test_advanced_queries(query_engine)
    
    # Interactive mode
    interactive_query(query_engine)
    
    print("\n✅ Query testing completed!")

if __name__ == "__main__":
    main() 