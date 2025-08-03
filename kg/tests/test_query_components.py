#!/usr/bin/env python3
"""Test script to verify the query components work correctly."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Mock the graph store for testing
class MockGraphStore:
    def __init__(self):
        self.entities = {}
        self.graph = MockGraph()
    
    def add_entity(self, name, entity_type=None, properties=None):
        entity_data = {'type': entity_type}
        if properties:
            entity_data.update(properties)
        self.entities[name] = entity_data
        self.graph.add_node(name)
    
    def get_entity(self, name):
        return self.entities.get(name)

class MockGraph:
    def __init__(self):
        self._nodes = set()
    
    def nodes(self):
        return list(self._nodes)
    
    def add_node(self, name):
        self._nodes.add(name)

class MockEmbeddingManager:
    pass

def test_filter_processor():
    """Test the filter processor with comparison operators."""
    print("Testing FilterProcessor with comparison operators...")
    
    # Import our modules
    from kg.query.filter_processors import FilterProcessor
    
    # Create mock data
    graph_store = MockGraphStore()
    
    # Add test entities
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
        }
    ]
    
    for entity in test_entities:
        graph_store.add_entity(
            entity['name'],
            entity_type=entity['type'],
            properties=entity
        )
    
    # Create filter processor
    filter_processor = FilterProcessor(graph_store)
    
    # Test 1: Direct property matching (should work before and after)
    print("\n1. Testing direct property matching:")
    candidates = list(graph_store.graph.nodes())
    properties_spec = {'file_extension': '.py'}
    filtered = filter_processor.filter_by_properties(candidates, properties_spec)
    print(f"   Input candidates: {candidates}")
    print(f"   Properties spec: {properties_spec}")
    print(f"   Filtered results: {filtered}")
    print(f"   Expected: ['file1.py', 'file2.py'] - {'✓' if set(filtered) == {'file1.py', 'file2.py'} else '✗'}")
    
    # Test 2: Comparison operators (the fix)
    print("\n2. Testing comparison operators (THE FIX):")
    candidates = list(graph_store.graph.nodes())
    properties_spec = {'created_date': {'gt': '2025-07-10'}}
    filtered = filter_processor.filter_by_properties(candidates, properties_spec)
    print(f"   Input candidates: {candidates}")
    print(f"   Properties spec: {properties_spec}")
    print(f"   Filtered results: {filtered}")
    print(f"   Expected: ['file1.py', 'file2.py'] - {'✓' if set(filtered) == {'file1.py', 'file2.py'} else '✗'}")
    
    # Test 3: Multiple conditions
    print("\n3. Testing multiple conditions:")
    candidates = list(graph_store.graph.nodes())
    properties_spec = {
        'file_extension': '.py',
        'size': {'gt': 1500}
    }
    filtered = filter_processor.filter_by_properties(candidates, properties_spec)
    print(f"   Input candidates: {candidates}")
    print(f"   Properties spec: {properties_spec}")
    print(f"   Filtered results: {filtered}")
    print(f"   Expected: ['file2.py'] - {'✓' if filtered == ['file2.py'] else '✗'}")

def test_condition_evaluator():
    """Test the condition evaluator."""
    print("\n\nTesting ConditionEvaluator...")
    
    from kg.query.condition_evaluators import ConditionEvaluator
    
    # Test data
    node_data = {
        'name': 'test_file.py',
        'file_extension': '.py',
        'created_date': '2025-07-11',
        'size': 1024
    }
    
    # Test various operators
    test_cases = [
        ('gt', 'size', 500, True),
        ('gt', 'size', 2000, False),
        ('lt', 'size', 2000, True),
        ('lt', 'size', 500, False),
        ('equals', 'file_extension', '.py', True),
        ('equals', 'file_extension', '.txt', False),
        ('gt', 'created_date', '2025-07-10', True),
        ('gt', 'created_date', '2025-07-12', False),
    ]
    
    print("\nTesting individual property conditions:")
    for operator, field, value, expected in test_cases:
        result = ConditionEvaluator.evaluate_property_condition(node_data, field, operator, value)
        status = '✓' if result == expected else '✗'
        print(f"   {field} {operator} {value} -> {result} (expected {expected}) {status}")

def main():
    print("Testing Query Engine Components")
    print("===============================")
    
    test_filter_processor()
    test_condition_evaluator()
    
    print("\n\n=== SUMMARY ===")
    print("The key fix was in FilterProcessor.filter_by_properties():")
    print("- OLD: Only handled direct equality: node_data.get(prop_name) != prop_value")
    print("- NEW: Handles nested operators: {created_date: {gt: '2025-07-10'}}")
    print("")
    print("This allows YAML queries like:")
    print("  properties:")
    print("    created_date:")
    print("      gt: '2025-07-10'")
    print("")
    print("Instead of only:")
    print("  properties:")
    print("    file_extension: '.py'")

if __name__ == "__main__":
    main()
