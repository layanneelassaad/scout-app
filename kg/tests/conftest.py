"""
Pytest configuration and fixtures for knowledge graph tests.
"""

import pytest
import os
import tempfile
from kg.graph_store import KnowledgeGraphStore
from kg.embeddings import EmbeddingManager
from kg.query_engine import KnowledgeGraphQueryEngine

@pytest.fixture
def query_engine():
    """Provide a query engine instance for tests."""
    # Use temporary storage for tests
    storage_path = "/tmp/test_kg_graph.json"
    cache_dir = "/tmp/test_kg_cache"
    
    # Initialize components
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager(cache_dir=cache_dir)
    query_engine = KnowledgeGraphQueryEngine(graph_store, embedding_manager)
    
    # Create some test data
    create_test_data(graph_store)
    
    return query_engine

def create_test_data(graph_store):
    """Create test data for query tests."""
    # Add test entities with various properties
    test_entities = [
        {
            "name": "file1.py",
            "type": "Document",
            "file_extension": ".py",
            "size": 2000,
            "created_date": "2025-07-15"
        },
        {
            "name": "file2.py", 
            "type": "Document",
            "file_extension": ".py",
            "size": 1800,
            "created_date": "2025-07-12"
        },
        {
            "name": "file3.txt",
            "type": "Document", 
            "file_extension": ".txt",
            "size": 500,
            "created_date": "2025-07-05"
        },
        {
            "name": "file4.py",
            "type": "Document",
            "file_extension": ".py", 
            "size": 1200,
            "created_date": "2025-07-08"
        }
    ]
    
    # Add entities to graph store
    for entity in test_entities:
        graph_store.add_entity(
            name=entity['name'],
            entity_type=entity['type'],
            properties=entity
        )
    
    print(f"Added {len(test_entities)} test entities for query tests") 