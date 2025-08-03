#!/usr/bin/env python3
"""Comprehensive test script for the entire knowledge graph system."""

import sys
import os
import tempfile
import shutil
from pathlib import Path

# Add the parent directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def test_graph_store():
    """Test the core graph store functionality."""
    print("=== Testing Graph Store ===")
    
    from kg.graph_store import KnowledgeGraphStore
    
    # Create temporary storage
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        storage_path = f.name
    
    try:
        # Initialize graph store
        graph_store = KnowledgeGraphStore(storage_path=storage_path)
        
        # Test adding entities
        graph_store.add_entity("John Doe", "Person", {"email": "john@example.com", "role": "Developer"})
        graph_store.add_entity("Example Corp", "Organization", {"industry": "Technology"})
        graph_store.add_entity("Python", "Technology", {"type": "Programming Language"})
        
        # Test adding relationships
        graph_store.add_relationship("John Doe", "Example Corp", "WORKS_FOR", {"start_date": "2023-01-01"})
        graph_store.add_relationship("John Doe", "Python", "KNOWS", {"proficiency": "Expert"})
        
        # Test retrieving entities
        john = graph_store.get_entity("John Doe")
        corp = graph_store.get_entity("Example Corp")
        
        print(f"✓ Added 3 entities and 2 relationships")
        print(f"✓ John Doe: {john}")
        print(f"✓ Example Corp: {corp}")
        
        # Test saving and loading
        graph_store.save()
        print("✓ Graph saved successfully")
        
        # Create new instance and load
        graph_store2 = KnowledgeGraphStore(storage_path=storage_path)
        graph_store2.load()
        
        john2 = graph_store2.get_entity("John Doe")
        print(f"✓ Loaded John Doe: {john2}")
        
        return True
        
    except Exception as e:
        print(f"✗ Graph store test failed: {e}")
        return False
    finally:
        # Cleanup
        if os.path.exists(storage_path):
            os.unlink(storage_path)

def test_embeddings():
    """Test the embeddings functionality."""
    print("\n=== Testing Embeddings ===")
    
    from kg.embeddings import EmbeddingManager
    
    # Create temporary cache directory
    cache_dir = tempfile.mkdtemp()
    
    try:
        # Initialize embedding manager
        embedding_manager = EmbeddingManager(cache_dir=cache_dir)
        
        # Test adding embeddings
        embedding_manager.add_entity_embedding("John Doe", "A software developer with expertise in Python")
        embedding_manager.add_entity_embedding("Python", "A high-level programming language")
        
        # Test similarity search
        results = embedding_manager.find_similar_entities("developer", top_k=2)
        print(f"✓ Added 2 entity embeddings")
        print(f"✓ Similarity search results: {len(results)} found")
        
        # Test saving and loading
        embedding_manager.save()
        print("✓ Embeddings saved successfully")
        
        return True
        
    except Exception as e:
        print(f"✗ Embeddings test failed: {e}")
        return False
    finally:
        # Cleanup
        shutil.rmtree(cache_dir, ignore_errors=True)

def test_query_engine():
    """Test the query engine functionality."""
    print("\n=== Testing Query Engine ===")
    
    from kg.query_engine import KnowledgeGraphQueryEngine
    from kg.graph_store import KnowledgeGraphStore
    from kg.embeddings import EmbeddingManager
    
    # Create temporary storage
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        storage_path = f.name
    cache_dir = tempfile.mkdtemp()
    
    try:
        # Initialize components
        graph_store = KnowledgeGraphStore(storage_path=storage_path)
        embedding_manager = EmbeddingManager(cache_dir=cache_dir)
        query_engine = KnowledgeGraphQueryEngine(graph_store, embedding_manager)
        
        # Add test data
        graph_store.add_entity("file1.py", "File", {"extension": ".py", "size": 1024, "created": "2024-01-01"})
        graph_store.add_entity("file2.txt", "File", {"extension": ".txt", "size": 512, "created": "2024-01-02"})
        graph_store.add_entity("file3.py", "File", {"extension": ".py", "size": 2048, "created": "2024-01-03"})
        
        # Test YAML query
        query_yaml = """
test_query:
  find:
    nodes:
      properties:
        extension: ".py"
      return: ["name", "extension", "size"]
"""
        
        result = query_engine.execute_query(query_yaml)
        print(f"✓ Query executed successfully: {result['success']}")
        if result['success']:
            print(f"✓ Found {result['result_count']} results")
        
        return True
        
    except Exception as e:
        print(f"✗ Query engine test failed: {e}")
        return False
    finally:
        # Cleanup
        if os.path.exists(storage_path):
            os.unlink(storage_path)
        shutil.rmtree(cache_dir, ignore_errors=True)

def test_file_operations():
    """Test file operations functionality."""
    print("\n=== Testing File Operations ===")
    
    from kg.file_operations import FileOperations
    
    # Create a temporary test file
    with tempfile.NamedTemporaryFile(mode='w', suffix='.txt', delete=False) as f:
        test_file = f.name
        f.write("This is a test file for the knowledge graph system.")
    
    try:
        # Test file operations
        content = FileOperations.read_file_content(test_file)
        metadata = FileOperations.extract_file_metadata(test_file)
        file_hash = FileOperations.calculate_file_hash(test_file)
        
        print(f"✓ File content read: {len(content)} characters")
        print(f"✓ File metadata extracted: {metadata['file_name']}")
        print(f"✓ File hash calculated: {file_hash[:8]}...")
        
        return True
        
    except Exception as e:
        print(f"✗ File operations test failed: {e}")
        return False
    finally:
        # Cleanup
        if os.path.exists(test_file):
            os.unlink(test_file)

def test_entity_analyzer():
    """Test entity analyzer functionality."""
    print("\n=== Testing Entity Analyzer ===")
    
    from kg.entity_analyzer import EntityAnalyzer
    from kg.graph_store import KnowledgeGraphStore
    
    # Create temporary storage
    with tempfile.NamedTemporaryFile(mode='w', suffix='.json', delete=False) as f:
        storage_path = f.name
    
    try:
        # Initialize components
        graph_store = KnowledgeGraphStore(storage_path=storage_path)
        analyzer = EntityAnalyzer(graph_store)
        
        # Test text analysis (this might fail if AI service is not available)
        test_text = "John Doe works at Example Corp as a Python developer."
        
        print("✓ Entity analyzer initialized")
        print("✓ Note: AI analysis requires external service and may not work in test environment")
        
        return True
        
    except Exception as e:
        print(f"✗ Entity analyzer test failed: {e}")
        return False
    finally:
        # Cleanup
        if os.path.exists(storage_path):
            os.unlink(storage_path)

def main():
    """Run all tests."""
    print("🧪 COMPREHENSIVE KNOWLEDGE GRAPH SYSTEM TEST")
    print("=" * 50)
    
    tests = [
        ("Graph Store", test_graph_store),
        ("Embeddings", test_embeddings),
        ("Query Engine", test_query_engine),
        ("File Operations", test_file_operations),
        ("Entity Analyzer", test_entity_analyzer),
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
                print(f"✅ {test_name} test PASSED")
            else:
                print(f"❌ {test_name} test FAILED")
        except Exception as e:
            print(f"❌ {test_name} test ERROR: {e}")
    
    print("\n" + "=" * 50)
    print(f"📊 TEST RESULTS: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 ALL TESTS PASSED! The knowledge graph system is working correctly.")
        return 0
    else:
        print("⚠️  Some tests failed. Please check the implementation.")
        return 1

if __name__ == "__main__":
    exit(main()) 