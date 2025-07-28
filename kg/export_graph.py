#!/usr/bin/env python3
"""Export knowledge graph to JSON format for visualization."""

import json
import sys
import os
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from graph_store import KnowledgeGraphStore

def export_graph_to_json(storage_path, output_path):
    """Export knowledge graph to JSON format."""
    try:
        # Load the graph store
        graph_store = KnowledgeGraphStore(storage_path=storage_path)
        # The graph is automatically loaded when initialized
        
        # Get all entities and relationships
        entities = []
        relationships = []
        
        # Export entities
        for node in graph_store.graph.nodes():
            entity_data = graph_store.get_entity(node)
            if entity_data:
                entities.append({
                    'id': node,
                    'type': entity_data.get('type', 'Unknown'),
                    'properties': {k: v for k, v in entity_data.items() if k not in ['type', 'created_at', 'updated_at']}
                })
        
        # Export relationships
        for source, target, data in graph_store.graph.edges(data=True):
            relationships.append({
                'source': source,
                'target': target,
                'type': data.get('type', 'unknown'),
                'properties': {k: v for k, v in data.items() if k not in ['type', 'weight', 'created_at']}
            })
        
        # Create the export structure
        export_data = {
            'nodes': entities,
            'links': relationships
        }
        
        # Save to JSON file
        with open(output_path, 'w') as f:
            json.dump(export_data, f, indent=2)
        
        print(f"✅ Exported {len(entities)} entities and {len(relationships)} relationships to {output_path}")
        return True
        
    except Exception as e:
        print(f"❌ Export failed: {e}")
        return False

def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Export knowledge graph to JSON')
    parser.add_argument('--storage', default='~/.mr_kg_data/knowledge_graph.json', 
                       help='Path to knowledge graph storage file')
    parser.add_argument('--output', default='kg_export.json',
                       help='Output JSON file path')
    
    args = parser.parse_args()
    
    # Expand user path
    storage_path = os.path.expanduser(args.storage)
    
    if not os.path.exists(storage_path):
        print(f"❌ Knowledge graph file not found: {storage_path}")
        print("💡 Try creating some entities first using the knowledge graph commands")
        return 1
    
    success = export_graph_to_json(storage_path, args.output)
    return 0 if success else 1

if __name__ == "__main__":
    exit(main()) 