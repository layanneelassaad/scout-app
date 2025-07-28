#!/usr/bin/env python3
"""Import existing knowledge graph data from kg_export.json."""

import sys
import os
import json
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'kg'))

from kg.graph_store import KnowledgeGraphStore
from kg.embeddings import EmbeddingManager

def import_existing_data():
    """Import existing data from kg_export.json."""
    
    print("📥 Importing existing knowledge graph data...")
    
    # Load the existing export data
    export_file = "kg/kg_export.json"
    if not os.path.exists(export_file):
        print(f"❌ Export file not found: {export_file}")
        return False
    
    with open(export_file, 'r') as f:
        export_data = json.load(f)
    
    print(f"📊 Found {len(export_data.get('nodes', []))} entities and {len(export_data.get('links', []))} relationships")
    
    # Initialize components
    storage_path = os.path.expanduser("~/.mr_kg_data")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    
    # Import entities
    entities_added = 0
    for node in export_data.get('nodes', []):
        entity_id = node.get('id')
        entity_type = node.get('type', 'Unknown')
        properties = node.get('properties', {})
        
        # Extract description from properties if available
        description = properties.get('description', '')
        
        success = graph_store.add_entity(
            name=entity_id,
            entity_type=entity_type,
            properties=properties,
            description=description
        )
        
        if success:
            entities_added += 1
            # Add embedding for search
            if description:
                embedding_manager.add_entity_embedding(entity_id, description)
    
    # Import relationships
    relationships_added = 0
    for link in export_data.get('links', []):
        source = link.get('source')
        target = link.get('target')
        rel_type = link.get('type', 'unknown')
        properties = link.get('properties', {})
        
        success = graph_store.add_relationship(
            from_entity=source,
            to_entity=target,
            relation_type=rel_type,
            properties=properties,
            weight=1.0
        )
        
        if success:
            relationships_added += 1
    
    # Save changes
    graph_store.save()
    embedding_manager.save()
    
    print(f"✅ Imported {entities_added} entities and {relationships_added} relationships")
    
    # Show statistics
    stats = graph_store.get_statistics()
    print(f"📊 Final Knowledge Graph Statistics:")
    print(f"   Entities: {stats.get('num_entities', 0)}")
    print(f"   Relationships: {stats.get('num_relationships', 0)}")
    
    return True

if __name__ == "__main__":
    import_existing_data() 