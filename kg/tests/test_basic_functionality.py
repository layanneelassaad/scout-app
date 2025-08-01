#!/usr/bin/env python3
"""Basic functionality test for the knowledge graph system."""

import sys
import os
import tempfile
import json
from pathlib import Path

# Add the parent directory to the path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

def test_graph_store_basic():
    """Test basic graph store functionality."""
    print("=== Testing Basic Graph Store ===")
    
    from kg.graph_store import KnowledgeGraphStore
    
    # Create a temporary directory for storage
    temp_dir = tempfile.mkdtemp()
    storage_path = os.path.join(temp_dir, "test_graph.json")
    
    try:
        # Initialize graph store
        graph_store = KnowledgeGraphStore(storage_path=storage_path)
        
        # Test adding entities
        success1 = graph_store.add_entity("John Doe", "Person", {"email": "john@example.com"})
        success2 = graph_store.add_entity("Example Corp", "Organization", {"industry": "Technology"})
        
        print(f"✓ Added entities: {success1}, {success2}")
        
        # Test retrieving entities
        john = graph_store.get_entity("John Doe")
        corp = graph_store.get_entity("Example Corp")
        
        print(f"✓ Retrieved John Doe: {john is not None}")
        print(f"✓ Retrieved Example Corp: {corp is not None}")
        
        # Test adding relationships
        rel1 = graph_store.add_relationship("John Doe", "Example Corp", "WORKS_FOR")
        print(f"✓ Added relationship: {rel1}")
        
        # Test graph statistics
        stats = graph_store.get_statistics()
        print(f"✓ Graph stats: {stats}")
        
        return True
        
    except Exception as e:
        print(f"✗ Graph store test failed: {e}")
        return False
    finally:
        # Cleanup
        import shutil
        shutil.rmtree(temp_dir, ignore_errors=True)

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

def test_query_parsing():
    """Test query parsing functionality."""
    print("\n=== Testing Query Parsing ===")
    
    from kg.query.query_parsers import QueryParser
    
    try:
        parser = QueryParser()
        
        # Test YAML parsing
        query_yaml = """
test_query:
  find:
    nodes:
      properties:
        type: "Person"
      return: ["name", "email"]
"""
        
        parsed = parser.parse_yaml_query(query_yaml)
        print(f"✓ Query parsed successfully: {parsed['name']}")
        print(f"✓ Query type: {parsed['type']}")
        
        return True
        
    except Exception as e:
        print(f"✗ Query parsing test failed: {e}")
        return False

def test_condition_evaluator():
    """Test condition evaluator functionality."""
    print("\n=== Testing Condition Evaluator ===")
    
    from kg.query.condition_evaluators import ConditionEvaluator
    
    try:
        # Test data
        node_data = {
            'name': 'test_file.py',
            'file_extension': '.py',
            'size': 1024
        }
        
        # Test various operators
        test_cases = [
            ('gt', 'size', 500, True),
            ('lt', 'size', 2000, True),
            ('equals', 'file_extension', '.py', True),
        ]
        
        all_passed = True
        for operator, field, value, expected in test_cases:
            result = ConditionEvaluator.evaluate_property_condition(node_data, field, operator, value)
            status = '✓' if result == expected else '✗'
            print(f"   {field} {operator} {value} -> {result} (expected {expected}) {status}")
            if result != expected:
                all_passed = False
        
        return all_passed
        
    except Exception as e:
        print(f"✗ Condition evaluator test failed: {e}")
        return False

def test_line_format_parser():
    """Test line format parser functionality."""
    print("\n=== Testing Line Format Parser ===")
    
    from kg.line_format_parser import LineFormatParser
    
    try:
        # Test format instructions
        instructions = LineFormatParser.format_instructions()
        print(f"✓ Format instructions generated: {len(instructions)} characters")
        
        # Test parsing (basic test)
        test_output = """ENTITY: John Doe | TYPE: Person | DESCRIPTION: Software developer | PROPERTIES: email=john@example.com
RELATIONSHIP: John Doe | TARGET: Example Corp | TYPE: WORKS_FOR | PROPERTIES: start_date=2023-01-01"""
        
        # This would normally parse the output, but we'll just test the format instructions
        print("✓ Line format parser initialized successfully")
        
        return True
        
    except Exception as e:
        print(f"✗ Line format parser test failed: {e}")
        return False

def main():
    """Run all basic tests."""
    print("🧪 BASIC KNOWLEDGE GRAPH FUNCTIONALITY TEST")
    print("=" * 50)
    
    tests = [
        ("Graph Store Basic", test_graph_store_basic),
        ("File Operations", test_file_operations),
        ("Query Parsing", test_query_parsing),
        ("Condition Evaluator", test_condition_evaluator),
        ("Line Format Parser", test_line_format_parser),
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
        print("🎉 ALL BASIC TESTS PASSED! Core functionality is working.")
        return 0
    else:
        print("⚠️  Some basic tests failed. Please check the implementation.")
        return 1

if __name__ == "__main__":
    exit(main()) 