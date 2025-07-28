#!/usr/bin/env python3
"""Simple script to add test documents to the knowledge graph for Swift app testing."""

import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'kg'))

from kg.graph_store import KnowledgeGraphStore
from kg.embeddings import EmbeddingManager

def add_test_documents():
    """Add test documents to the knowledge graph."""
    
    # Initialize components
    storage_path = os.path.expanduser("~/.mr_kg_data")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    
    # Test documents data
    test_docs = [
        {
            "name": "John Smith",
            "type": "Person",
            "description": "Lead developer and consultant who works with Google, Microsoft, and Acme Corporation",
            "properties": {
                "email": "john.smith@consulting.com",
                "phone": "(555) 123-4567",
                "role": "Lead Developer"
            }
        },
        {
            "name": "Google Inc.",
            "type": "Organization", 
            "description": "Technology company that received AI-Powered Analytics Platform Development proposal",
            "properties": {
                "industry": "Technology",
                "project": "AI-Powered Analytics Platform"
            }
        },
        {
            "name": "Microsoft Corporation",
            "type": "Organization",
            "description": "Technology company that hired John Smith for cloud migration consulting",
            "properties": {
                "industry": "Technology",
                "project": "Cloud Migration"
            }
        },
        {
            "name": "Acme Corporation",
            "type": "Organization",
            "description": "Client company that hired John Smith for e-commerce platform redesign",
            "properties": {
                "industry": "E-commerce",
                "project": "E-commerce Platform Redesign"
            }
        },
        {
            "name": "AI-Powered Analytics Platform",
            "type": "Project",
            "description": "Machine learning platform for Google's internal data analysis needs",
            "properties": {
                "budget": "$250,000",
                "duration": "16 weeks",
                "client": "Google Inc."
            }
        },
        {
            "name": "Cloud Migration Project",
            "type": "Project", 
            "description": "Software architecture consulting for Microsoft's cloud migration",
            "properties": {
                "budget": "$96,000",
                "duration": "3 months",
                "client": "Microsoft Corporation"
            }
        },
        {
            "name": "E-commerce Platform Redesign",
            "type": "Project",
            "description": "Web development services for Acme's e-commerce platform redesign",
            "properties": {
                "budget": "$75,000", 
                "duration": "6 months",
                "client": "Acme Corporation"
            }
        }
    ]
    
    # Add entities
    for doc in test_docs:
        success = graph_store.add_entity(
            name=doc["name"],
            entity_type=doc["type"],
            properties=doc.get("properties", {}),
            description=doc["description"]
        )
        if success:
            print(f"✅ Added: {doc['name']} ({doc['type']})")
            # Add embedding for search
            embedding_manager.add_entity_embedding(doc["name"], doc["description"])
        else:
            print(f"❌ Failed to add: {doc['name']}")
    
    # Add relationships
    relationships = [
        ("John Smith", "works_for", "Google Inc."),
        ("John Smith", "works_for", "Microsoft Corporation"), 
        ("John Smith", "works_for", "Acme Corporation"),
        ("John Smith", "leads", "AI-Powered Analytics Platform"),
        ("John Smith", "consults_on", "Cloud Migration Project"),
        ("John Smith", "develops", "E-commerce Platform Redesign"),
        ("AI-Powered Analytics Platform", "for", "Google Inc."),
        ("Cloud Migration Project", "for", "Microsoft Corporation"),
        ("E-commerce Platform Redesign", "for", "Acme Corporation")
    ]
    
    for source, rel_type, target in relationships:
        success = graph_store.add_relationship(
            from_entity=source,
            to_entity=target,
            relation_type=rel_type,
            properties={},
            weight=1.0
        )
        if success:
            print(f"✅ Added relationship: {source} --{rel_type}--> {target}")
        else:
            print(f"❌ Failed to add relationship: {source} --{rel_type}--> {target}")
    
    # Save changes
    graph_store.save()
    embedding_manager.save()
    
    # Show statistics
    stats = graph_store.get_statistics()
    print(f"\n📊 Knowledge Graph Statistics:")
    print(f"   Entities: {stats.get('num_entities', 0)}")
    print(f"   Relationships: {stats.get('num_relationships', 0)}")
    print(f"\n✅ Test data added successfully!")

if __name__ == "__main__":
    add_test_documents() 