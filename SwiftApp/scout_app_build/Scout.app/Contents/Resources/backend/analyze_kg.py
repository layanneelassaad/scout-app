#!/usr/bin/env python3
"""
Knowledge Graph Analysis Script

Analyzes the structure of the knowledge graph and provides detailed information
about entities and relationships.
"""

import json
import sys
from collections import defaultdict

def analyze_knowledge_graph(kg_json_path):
    """Analyze the knowledge graph structure."""
    
    # Load the exported graph data
    with open(kg_json_path, 'r') as f:
        data = json.load(f)

    nodes = data['nodes']
    edges = data['links']
    
    print("🧠 KNOWLEDGE GRAPH ANALYSIS")
    print("=" * 50)
    
    # Analyze entities by type
    entity_types = defaultdict(list)
    for node in nodes:
        entity_type = node.get('type', 'Unknown')
        entity_types[entity_type].append(node)
    
    print(f"\n📊 ENTITY ANALYSIS:")
    print(f"Total entities: {len(nodes)}")
    for entity_type, entities in entity_types.items():
        print(f"  {entity_type}: {len(entities)} entities")
        for entity in entities:
            entity_id = entity['id']
            if entity_type == 'File':
                print(f"    - {entity_id}")
            elif entity_type == 'TextChunk':
                # Show just the source file for chunks
                source_file = entity.get('properties', {}).get('file_name', 'Unknown')
                word_count = entity.get('properties', {}).get('word_count', 0)
                print(f"    - {source_file} (chunk, {word_count} words)")
    
    # Analyze relationships by type
    relationship_types = defaultdict(list)
    for edge in edges:
        rel_type = edge.get('type', 'Unknown')
        relationship_types[rel_type].append(edge)
    
    print(f"\n🔗 RELATIONSHIP ANALYSIS:")
    print(f"Total relationships: {len(edges)}")
    for rel_type, relationships in relationship_types.items():
        print(f"  {rel_type}: {len(relationships)} relationships")
        for rel in relationships:
            source = rel['source']
            target = rel['target']
            print(f"    - {source} → {target}")
    
    # Show content summary for each file
    print(f"\n📄 CONTENT SUMMARY:")
    for node in nodes:
        if node.get('type') == 'File':
            file_name = node['id']
            properties = node.get('properties', {})
            file_size = properties.get('file_size', 0)
            print(f"\n  {file_name}:")
            print(f"    Size: {file_size} bytes")
            print(f"    Path: {properties.get('full_path', 'Unknown')}")
            
            # Find corresponding chunk
            for chunk_node in nodes:
                if chunk_node.get('type') == 'TextChunk':
                    chunk_props = chunk_node.get('properties', {})
                    if chunk_props.get('file_name') == properties.get('file_name'):
                        content = chunk_props.get('description', '')
                        # Show first 200 characters
                        preview = content[:200].replace('\n', ' ')
                        if len(content) > 200:
                            preview += "..."
                        print(f"    Content preview: {preview}")
                        break
    
    # Check for potential issues
    print(f"\n🔍 QUALITY CHECKS:")
    
    # Check if files have chunks
    files_with_chunks = set()
    for edge in edges:
        if edge.get('type') == 'contains_chunk':
            files_with_chunks.add(edge['source'])
    
    file_entities = [node for node in nodes if node.get('type') == 'File']
    for file_entity in file_entities:
        file_id = file_entity['id']
        if file_id in files_with_chunks:
            print(f"  ✅ {file_id}: Has content chunks")
        else:
            print(f"  ⚠️  {file_id}: No content chunks found")
    
    # Check for AI-extracted entities
    ai_entities = [node for node in nodes if node.get('type') not in ['File', 'TextChunk']]
    if ai_entities:
        print(f"  ✅ AI-extracted entities found: {len(ai_entities)}")
        for entity in ai_entities:
            print(f"    - {entity['id']} ({entity.get('type', 'Unknown')})")
    else:
        print(f"  ⚠️  No AI-extracted entities found (AI analysis may not be working)")
    
    print(f"\n" + "=" * 50)

def main():
    """Main function."""
    if len(sys.argv) != 2:
        print("Usage: python analyze_kg.py <kg_export.json>")
        sys.exit(1)
    
    kg_json_path = sys.argv[1]
    
    try:
        analyze_knowledge_graph(kg_json_path)
    except FileNotFoundError:
        print(f"❌ File not found: {kg_json_path}")
        sys.exit(1)
    except json.JSONDecodeError:
        print(f"❌ Invalid JSON file: {kg_json_path}")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Error analyzing knowledge graph: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main() 