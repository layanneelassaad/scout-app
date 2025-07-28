"""MindRoot Knowledge Graph Plugin - Core graph operation commands."""

import os
import json
import yaml
import logging
from typing import Dict, List, Any, Optional
from lib.providers.commands import command
from lib.providers.services import service_manager

from .mod import _get_graph_store, _get_embedding_manager, _get_query_engine, _get_file_indexer

logger = logging.getLogger(__name__)

@command()
async def kg_add_entity(name, entity_type, properties=None, description=None, context=None):
    """Add an entity to the knowledge graph.
    
    Args:
        name: Entity name (unique identifier)
        entity_type: Type of entity (Person, Organization, Concept, etc.)
        properties: Additional properties as dictionary
        description: Text description for semantic search
    
    Example:
        {"kg_add_entity": {
            "name": "John Smith",
            "entity_type": "Person",
            "properties": {"age": 35, "occupation": "Engineer"},
            "description": "Software engineer specializing in AI"
        }}
    """
    try:
        graph_store = _get_graph_store()
        embedding_manager = _get_embedding_manager()
        
        # Add entity to graph
        success = graph_store.add_entity(name, entity_type, properties, description)
        
        if success:
            # Add embedding
            desc_text = description or name
            embedding_manager.add_entity_embedding(name, desc_text)
            
            # Save state
            graph_store.save()
            embedding_manager.save()
            
            return {
                'success': True,
                'entity': name,
                'type': entity_type,
                'message': f'Entity "{name}" added successfully'
            }
        else:
            return {
                'success': False,
                'error': 'Failed to add entity to graph'
            }
        
    except Exception as e:
        logger.error(f"Error adding entity: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_add_relationship(from_entity, to_entity, relation_type, properties=None, weight=1.0, context=None):
    """Add a relationship between entities.
    
    Args:
        from_entity: Source entity name
        to_entity: Target entity name
        relation_type: Type of relationship (knows, works_at, etc.)
        properties: Additional relationship properties
        weight: Relationship strength (0.0 to 1.0)
    
    Example:
        {"kg_add_relationship": {
            "from_entity": "John Smith",
            "to_entity": "Acme Corp",
            "relation_type": "works_at",
            "properties": {"role": "Senior Engineer", "since": "2020"}
        }}
    """
    try:
        graph_store = _get_graph_store()
        
        success = graph_store.add_relationship(
            from_entity, to_entity, relation_type, properties, weight
        )
        
        if success:
            graph_store.save()
            return {
                'success': True,
                'relationship': f'{from_entity} --[{relation_type}]--> {to_entity}',
                'message': 'Relationship added successfully'
            }
        else:
            return {
                'success': False,
                'error': 'Failed to add relationship'
            }
        
    except Exception as e:
        logger.error(f"Error adding relationship: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_search(query, limit=10, semantic=True, threshold=0.7, context=None):
    """Search entities in the knowledge graph.
    
    Args:
        query: Search query text
        limit: Maximum number of results
        semantic: Use semantic similarity search
        threshold: Minimum similarity threshold (0.0 to 1.0)
    
    Example:
        {"kg_search": {
            "query": "software engineer",
            "limit": 5,
            "semantic": true,
            "threshold": 0.7
        }}
    """
    try:
        if semantic:
            embedding_manager = _get_embedding_manager()
            results = embedding_manager.find_similar(query, k=limit, threshold=threshold)
            
            # Enrich with graph data
            graph_store = _get_graph_store()
            enriched_results = []
            
            for result in results:
                entity_data = graph_store.get_entity(result['entity'])
                if entity_data:
                    enriched_result = {
                        'entity': result['entity'],
                        'score': result['score'],
                        'type': entity_data.get('type', 'Unknown'),
                        'description': entity_data.get('description', ''),
                        'properties': {k: v for k, v in entity_data.items() 
                                     if k not in ['type', 'description', 'created_at']}
                    }
                    enriched_results.append(enriched_result)
            
            return {
                'success': True,
                'query': query,
                'results': enriched_results,
                'search_type': 'semantic'
            }
        else:
            # Text-based search
            graph_store = _get_graph_store()
            results = graph_store.search_entities(query)
            
            formatted_results = []
            for entity, data in results[:limit]:
                formatted_results.append({
                    'entity': entity,
                    'type': data.get('type', 'Unknown'),
                    'description': data.get('description', ''),
                    'properties': {k: v for k, v in data.items() 
                                 if k not in ['type', 'description', 'created_at']}
                })
            
            return {
                'success': True,
                'query': query,
                'results': formatted_results,
                'search_type': 'text'
            }
        
    except Exception as e:
        logger.error(f"Error searching: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_query_graph(entity, depth=2, relation_types=None, direction="both", context=None):
    """Query graph structure around an entity.
    
    Args:
        entity: Starting entity name
        depth: Maximum traversal depth
        relation_types: List of relationship types to follow
    
    Example:
        {"kg_query_graph": {
            "entity": "John Smith",
            "depth": 2,
            "relation_types": ["knows", "works_with"]
        }}
    """
    try:
        graph_store = _get_graph_store()
        
        # Find connected entities
        connected = graph_store.find_connected_entities(
            entity, max_depth=depth, relation_types=relation_types, direction=direction
        )
        
        # Get subgraph
        all_entities = [entity] + connected
        subgraph = graph_store.get_subgraph(all_entities)
        
        # Prepare result
        nodes = []
        edges = []
        
        for node, data in subgraph.nodes(data=True):
            nodes.append({
                'id': node,
                'type': data.get('type', 'Unknown'),
                'description': data.get('description', ''),
                'properties': {k: v for k, v in data.items() 
                             if k not in ['type', 'description', 'created_at']}
            })
        
        for source, target, data in subgraph.edges(data=True):
            edges.append({
                'source': source,
                'target': target,
                'type': data.get('type', 'Unknown'),
                'weight': data.get('weight', 1.0),
                'properties': {k: v for k, v in data.items() 
                             if k not in ['type', 'weight', 'created_at']}
            })
        
        return {
            'success': True,
            'center_entity': entity,
            'depth': depth,
            'nodes': nodes,
            'edges': edges,
            'node_count': len(nodes),
            'edge_count': len(edges)
        }
        
    except Exception as e:
        logger.error(f"Error querying graph: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_yaml_query(query_yaml, context=None):
    """Execute YAML-based knowledge graph query with advanced filtering, connectivity, sorting, and limiting.
    
    The YAML query system supports powerful graph traversal, semantic search, filtering,
    sorting, and result limiting capabilities.
    
    Args:
        query_yaml: YAML query string defining the search criteria
    
    ## Basic Query Structure:
    ```yaml
    query_name:
      find:
        nodes:
          type: EntityType          # Filter by entity type
          name: "Exact Name"        # Exact name match
          similar_to: "search text" # Semantic similarity search
          threshold: 0.7            # Similarity threshold (0.0-1.0)
          description:
            contains: "keyword"     # Description contains text
        relations: ["rel1", "rel2"] # Relationship types to follow
        depth: 2                    # Maximum traversal depth
        order_by: field_name        # Simple sorting
        order: asc                  # Sort direction (asc/desc)
        limit: 10                   # Maximum results
        return: ["name", "type", "description"]
    ```
    
    ## Advanced Multi-field Sorting:
    ```yaml
    query_name:
      find:
        nodes:
          type: Person
        order_by:
          - field: created_at
            direction: desc
          - field: name
            direction: asc
        limit: 5
        return: ["name", "created_at"]
    ```
    
    ## Examples:
    
    ### 1. Find People by Semantic Search (Sorted & Limited):
    ```yaml
    find_ai_experts:
      find:
        nodes:
          type: Person
          similar_to: "artificial intelligence expert"
          threshold: 0.8
        order_by: name
        order: asc
        limit: 5
        return: ["name", "description", "properties"]
    ```
    
    ### 2. Connectivity Query with Relationship Filtering:
    ```yaml
    find_communications:
      find:
        nodes:
          type: Person
          name: "Eric Livesay"
        relations: ["sent", "mentions", "received"]
        depth: 2
        order_by: name
        order: desc
        limit: 10
        return: ["name", "type", "description"]
    ```
    
    ### 3. Advanced Multi-field Sorting:
    ```yaml
    find_recent_entities:
      find:
        nodes:
          type: Person
        order_by:
          - field: created_at
            direction: desc
          - field: name
            direction: asc
        limit: 3
        return: ["name", "created_at", "description"]
    ```
    
    ### 4. Complex Filtering with Properties:
    ```yaml
    find_active_users:
      find:
        nodes:
          type: Person
          properties:
            status: "active"
            role: "engineer"
        description:
          contains: "software"
        order_by: name
        limit: 20
        return: ["name", "properties", "description"]
    ```
    
    ### 5. Semantic Search with Connectivity:
    ```yaml
    find_related_concepts:
      find:
        nodes:
          similar_to: "machine learning"
          threshold: 0.6
        relations: ["related_to", "mentions"]
        depth: 1
        order_by:
          - field: type
            direction: asc
          - field: name
            direction: asc
        limit: 15
        return: ["name", "type", "description"]
    ```
    
    ## Query Parameters:
    
    ### Node Filtering:
    - `type`: Filter by entity type (Person, Organization, etc.)
    - `name`: Exact name match
    - `similar_to`: Semantic similarity search text
    - `threshold`: Similarity threshold (0.0-1.0, default 0.5)
    - `description.contains`: Description contains text
    - `properties`: Dictionary of property filters
    
    ### Connectivity:
    - `relations`: List of relationship types to follow
    - `depth`: Maximum traversal depth (default 2)
    
    ### Sorting:
    - `order_by`: Field name for simple sorting OR list of field objects for advanced
    - `order`: "asc" or "desc" for simple sorting
    - Advanced format: `[{field: "name", direction: "asc"}, ...]`
    
    ### Limiting:
    - `limit`: Maximum number of results to return
    
    ### Return Fields:
    - `return`: List of fields to include in results
    - Available: "name", "type", "description", "properties", "created_at", "updated_at"
    
    ## Sortable Fields:
    - `name`: Entity name (alphabetical)
    - `type`: Entity type
    - `description`: Description text
    - `created_at`: Creation timestamp
    - `updated_at`: Last update timestamp
    - Any custom property fields
    
    ## Return Format:
    
    ### For Connectivity Queries (with relations/depth):
    ```json
    {
      "success": true,
      "results": {
        "nodes": [{"name": "...", "type": "...", ...}],
        "edges": [{"source": "...", "target": "...", "type": "..."}],
        "starting_nodes": ["Eric Livesay"],
        "connected_nodes": ["...", "..."],
        "node_count": 10,
        "edge_count": 25
      }
    }
    ```
    
    ### For Simple Node Queries:
    ```json
    {
      "success": true,
      "results": [
        {"name": "John Doe", "type": "Person", "description": "..."},
        {"name": "Jane Smith", "type": "Person", "description": "..."}
      ]
    }
    ```
    
    ## Usage Examples:
    
    ```python
    # Simple entity search
    {"kg_yaml_query": {
        "query_yaml": "find_people:\n  find:\n    nodes:\n      type: Person\n    limit: 5\n    return: ['name', 'description']"
    }}
    
    # Connectivity with sorting
    {"kg_yaml_query": {
        "query_yaml": "find_connections:\n  find:\n    nodes:\n      name: 'Eric Livesay'\n    relations: ['sent', 'mentions']\n    depth: 1\n    order_by: name\n    order: desc\n    limit: 10\n    return: ['name', 'type']"
    }}
    ```
    """
    try:
        query_engine = _get_query_engine()
        result = query_engine.execute_query(query_yaml)
        return result
        
    except Exception as e:
        logger.error(f"Error executing YAML query: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_natural_to_yaml(natural_query, context=None):
    """Convert natural language query to YAML format.
    
    Args:
        natural_query: Natural language query string
    
    Example:
        {"kg_natural_to_yaml": {
            "natural_query": "Find people who work in AI and are connected to Stanford"
        }}
    """
    try:
        # This would ideally use an AI service to convert natural language to YAML
        # For now, we'll provide some basic templates
        
        query_lower = natural_query.lower()
        
        if 'find' in query_lower and 'people' in query_lower:
            # Generate person search query
            yaml_query = f"""find_people:
  find:
    nodes:
      type: Person
      similar_to: "{natural_query}"
      threshold: 0.7
    return:
      - name
      - type
      - description"""
        elif 'path' in query_lower or 'connection' in query_lower:
            # Generate path finding query
            yaml_query = f"""find_connection:
  find_path:
    from_semantic: "source entity"
    to_semantic: "target entity"
    max_hops: 3
    return:
      - path
      - length"""
        else:
            # Generic search query
            yaml_query = f"""general_search:
  find:
    nodes:
      similar_to: "{natural_query}"
      threshold: 0.6
    return:
      - entity
      - type
      - description"""
        
        return {
            'success': True,
            'natural_query': natural_query,
            'yaml_query': yaml_query,
            'note': 'This is a basic conversion. For advanced queries, consider using the YAML format directly.'
        }
        
    except Exception as e:
        logger.error(f"Error converting natural query: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_get_stats(context=None):
    """Get knowledge graph statistics.
    
    Example:
        {"kg_get_stats": {}}
    """
    try:
        graph_store = _get_graph_store()
        embedding_manager = _get_embedding_manager()
        
        graph_stats = graph_store.get_statistics()
        embedding_stats = embedding_manager.get_stats()
        
        return {
            'success': True,
            'graph': graph_stats,
            'embeddings': embedding_stats
        }
        
    except Exception as e:
        logger.error(f"Error getting stats: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_visualize(entity=None, depth=2, format='json', context=None):
    """Generate visualization data for the knowledge graph.
    
    Args:
        entity: Center entity for subgraph (None for full graph)
        depth: Maximum depth for subgraph
        format: Output format ('json', 'cytoscape', 'd3')
    
    Example:
        {"kg_visualize": {
            "entity": "John Smith",
            "depth": 2,
            "format": "cytoscape"
        }}
    """
    try:
        graph_store = _get_graph_store()
        
        if entity:
            # Get subgraph around entity
            connected = graph_store.find_connected_entities(entity, max_depth=depth)
            all_entities = [entity] + connected
            subgraph = graph_store.get_subgraph(all_entities)
        else:
            # Use full graph
            subgraph = graph_store.graph
        
        if format.lower() == 'cytoscape':
            # Cytoscape.js format
            elements = []
            
            # Add nodes
            for node, data in subgraph.nodes(data=True):
                elements.append({
                    'data': {
                        'id': node,
                        'label': node,
                        'type': data.get('type', 'Unknown'),
                        'description': data.get('description', '')
                    }
                })
            
            # Add edges
            for source, target, data in subgraph.edges(data=True):
                elements.append({
                    'data': {
                        'id': f"{source}-{target}",
                        'source': source,
                        'target': target,
                        'label': data.get('type', 'Unknown'),
                        'weight': data.get('weight', 1.0)
                    }
                })
            
            return {
                'success': True,
                'format': 'cytoscape',
                'elements': elements
            }
        
        elif format.lower() == 'd3':
            # D3.js format
            nodes = []
            links = []
            node_index = {}
            
            # Add nodes
            for i, (node, data) in enumerate(subgraph.nodes(data=True)):
                node_index[node] = i
                nodes.append({
                    'id': node,
                    'name': node,
                    'type': data.get('type', 'Unknown'),
                    'description': data.get('description', ''),
                    'group': hash(data.get('type', 'Unknown')) % 10
                })
            
            # Add links
            for source, target, data in subgraph.edges(data=True):
                links.append({
                    'source': node_index[source],
                    'target': node_index[target],
                    'type': data.get('type', 'Unknown'),
                    'weight': data.get('weight', 1.0)
                })
            
            return {
                'success': True,
                'format': 'd3',
                'nodes': nodes,
                'links': links
            }
        
        else:
            # Default JSON format
            import networkx as nx
            graph_data = nx.node_link_data(subgraph)
            
            return {
                'success': True,
                'format': 'json',
                'graph': graph_data
            }
        
    except Exception as e:
        logger.error(f"Error generating visualization: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_export(format='json', output_path=None, context=None):
    """Export knowledge graph to file.
    
    Args:
        format: Export format ('json', 'graphml', 'gexf', 'csv')
        output_path: Output file path (auto-generated if None)
    
    Example:
        {"kg_export": {
            "format": "json",
            "output_path": "/path/to/export.json"
        }}
    """
    try:
        graph_store = _get_graph_store()
        
        if output_path is None:
            # Auto-generate path
            import tempfile
            temp_dir = tempfile.gettempdir()
            output_path = os.path.join(temp_dir, f"knowledge_graph.{format}")
        
        success = graph_store.export_to_format(format, output_path)
        
        if success:
            return {
                'success': True,
                'format': format,
                'output_path': output_path,
                'message': f'Graph exported to {output_path}'
            }
        else:
            return {
                'success': False,
                'error': 'Export failed'
            }
        
    except Exception as e:
        logger.error(f"Error exporting graph: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_import(format='json', input_path=None, context=None):
    """Import knowledge graph from file.
    
    Args:
        format: Import format ('json', 'graphml', 'gexf')
        input_path: Input file path
    
    Example:
        {"kg_import": {
            "format": "json",
            "input_path": "/path/to/import.json"
        }}
    """
    try:
        if not input_path:
            return {
                'success': False,
                'error': 'input_path is required'
            }
        
        if not os.path.exists(input_path):
            return {
                'success': False,
                'error': f'File not found: {input_path}'
            }
        
        graph_store = _get_graph_store()
        success = graph_store.import_from_format(format, input_path)
        
        if success:
            # Save the imported graph
            graph_store.save()
            
            return {
                'success': True,
                'format': format,
                'input_path': input_path,
                'message': f'Graph imported from {input_path}'
            }
        else:
            return {
                'success': False,
                'error': 'Import failed'
            }
        
    except Exception as e:
        logger.error(f"Error importing graph: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_list_by_type(entity_type, context=None):
    """List all entities of a specific type.
    
    Args:
        entity_type: Type of entities to list
    
    Example:
        {"kg_list_by_type": {
            "entity_type": "Person"
        }}
    """
    try:
        graph_store = _get_graph_store()
        
        results = graph_store.get_entities_by_type(entity_type)
        
        formatted_results = []
        for entity, data in results:
            formatted_results.append({
                'entity': entity,
                'type': data.get('type', 'Unknown'),
                'description': data.get('description', ''),
                'properties': {k: v for k, v in data.items() 
                             if k not in ['type', 'description', 'created_at']}
            })
        
        return {
            'success': True,
            'entity_type': entity_type,
            'results': formatted_results,
            'count': len(formatted_results)
        }
        
    except Exception as e:
        logger.error(f"Error listing entities by type: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_list_types(context=None):
    """List all entity types in the knowledge graph.
    
    Example:
        {"kg_list_types": {}}
    """
    try:
        graph_store = _get_graph_store()
        
        types = graph_store.get_all_entity_types()
        
        # Get counts for each type
        type_counts = {}
        for node, data in graph_store.graph.nodes(data=True):
            entity_type = data.get('type', 'Unknown')
            type_counts[entity_type] = type_counts.get(entity_type, 0) + 1
        
        type_info = []
        for entity_type in types:
            type_info.append({
                'type': entity_type,
                'count': type_counts.get(entity_type, 0)
            })
        
        return {
            'success': True,
            'types': type_info,
            'total_types': len(types)
        }
        
    except Exception as e:
        logger.error(f"Error listing entity types: {e}")
        return {
            'success': False,
            'error': str(e)
        }