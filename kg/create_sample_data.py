#!/usr/bin/env python3
"""Create sample data in the knowledge graph for visualization testing."""

import sys
import os
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from graph_store import KnowledgeGraphStore

def create_sample_data():
    """Create sample entities and relationships for visualization."""
    
    # Initialize graph store
    storage_path = os.path.expanduser("~/.mr_kg_data/knowledge_graph.json")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    
    # Create sample entities
    entities = [
        ("John Doe", "Person", {"email": "john@example.com", "role": "Software Developer", "skills": ["Python", "JavaScript"]}),
        ("Jane Smith", "Person", {"email": "jane@example.com", "role": "Product Manager", "department": "Product"}),
        ("Example Corp", "Organization", {"industry": "Technology", "size": "Medium", "founded": "2020"}),
        ("Python", "Technology", {"type": "Programming Language", "paradigm": "Object-Oriented"}),
        ("JavaScript", "Technology", {"type": "Programming Language", "paradigm": "Multi-Paradigm"}),
        ("React", "Technology", {"type": "Framework", "language": "JavaScript"}),
        ("Project Alpha", "Project", {"status": "Active", "priority": "High", "start_date": "2024-01-01"}),
        ("San Francisco", "Location", {"country": "USA", "state": "California", "type": "City"}),
    ]
    
    # Add entities
    for name, entity_type, properties in entities:
        success = graph_store.add_entity(name, entity_type, properties)
        print(f"✓ Added entity: {name} ({entity_type})")
    
    # Create sample relationships
    relationships = [
        ("John Doe", "Example Corp", "WORKS_FOR", {"start_date": "2023-01-01", "position": "Developer"}),
        ("Jane Smith", "Example Corp", "WORKS_FOR", {"start_date": "2022-06-01", "position": "Manager"}),
        ("John Doe", "Python", "KNOWS", {"proficiency": "Expert", "years": 5}),
        ("John Doe", "JavaScript", "KNOWS", {"proficiency": "Intermediate", "years": 3}),
        ("Jane Smith", "Project Alpha", "MANAGES", {"role": "Project Manager"}),
        ("John Doe", "Project Alpha", "WORKS_ON", {"role": "Developer"}),
        ("Example Corp", "San Francisco", "LOCATED_IN", {"office_type": "Headquarters"}),
        ("React", "JavaScript", "BUILT_WITH", {"version": "18.0"}),
        ("Project Alpha", "Python", "USES", {"purpose": "Backend Development"}),
        ("Project Alpha", "React", "USES", {"purpose": "Frontend Development"}),
    ]
    
    # Add relationships
    for source, target, rel_type, properties in relationships:
        success = graph_store.add_relationship(source, target, rel_type, properties)
        print(f"✓ Added relationship: {source} --{rel_type}--> {target}")
    
    # Save the graph
    graph_store.save()
    
    # Print statistics
    stats = graph_store.get_statistics()
    print(f"\n📊 Graph Statistics:")
    print(f"   Entities: {stats['num_entities']}")
    print(f"   Relationships: {stats['num_relationships']}")
    
    print(f"\n✅ Sample data created successfully!")
    print(f"💾 Graph saved to: {storage_path}")

if __name__ == "__main__":
    create_sample_data() 