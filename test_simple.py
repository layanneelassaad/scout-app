#!/usr/bin/env python3
"""Simple test to add an entity and save it."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'kg'))

from kg.graph_store import KnowledgeGraphStore
from kg.embeddings import EmbeddingManager

def test_simple():
    """Test adding an entity and saving."""
    
    print("🔍 Testing simple entity addition...")
    
    # Initialize components
    storage_path = os.path.expanduser("~/.mr_kg_data")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    
    # Add a simple entity
    success = graph_store.add_entity(
        name="Test Person",
        entity_type="Person",
        properties={"email": "test@example.com"},
        description="A test person for testing"
    )
    
    if success:
        print("✅ Entity added successfully")
        
        # Save the graph
        graph_store.save()
        print("✅ Graph saved")
        
        # Check file size
        import os
        file_path = os.path.join(storage_path, 'knowledge_graph.json')
        if os.path.exists(file_path):
            size = os.path.getsize(file_path)
            print(f"📁 File size: {size} bytes")
            
            if size > 0:
                print("✅ File has content")
                # Read and show content
                with open(file_path, 'r') as f:
                    content = f.read()
                    print(f"📄 Content preview: {content[:200]}...")
            else:
                print("❌ File is empty")
        else:
            print("❌ File doesn't exist")
    else:
        print("❌ Failed to add entity")

if __name__ == "__main__":
    test_simple() 