"""Command for consolidating multiple entities into one in the knowledge graph."""

import logging
from typing import List, Dict, Any, Optional
from lib.providers.commands import command
from .mod import _get_graph_store, _get_embedding_manager

logger = logging.getLogger(__name__)

@command()
async def kg_consolidate_entities(
    entity_ids: List[str],
    target_entity: str,
    entity_type: str,
    properties: Optional[Dict] = None,
    description: Optional[str] = None,
    context=None
):
    """Consolidate multiple entities into a single entity.
    
    This command merges multiple entities into one by:
    1. Creating or updating the target entity with the provided definition
    2. Redirecting all relationships from the old entities to the new one
    3. Removing the old entities from the graph
    
    Args:
        entity_ids: List of entity IDs to consolidate (these will be removed)
        target_entity: The name of the consolidated entity (will be created/updated)
        entity_type: Type of the consolidated entity
        properties: Properties for the consolidated entity
        description: Description for the consolidated entity
    
    Example:
        {"kg_consolidate_entities": {
            "entity_ids": ["run vnc", "Ilaksh"],
            "target_entity": "Jason",
            "entity_type": "Person",
            "properties": {"email": "runvnc@gmail.com", "hn_alias": "Ilaksh"},
            "description": "Jason, also known as Ilaksh on HN, email: runvnc@gmail.com"
        }}
    """
    try:
        graph_store = _get_graph_store()
        embedding_manager = _get_embedding_manager()
        
        # Validate inputs
        if not entity_ids:
            return {
                'success': False,
                'error': 'No entity IDs provided for consolidation'
            }
        
        if not target_entity or not entity_type:
            return {
                'success': False,
                'error': 'target_entity and entity_type are required'
            }
        
        # Check that all source entities exist
        missing_entities = []
        for entity_id in entity_ids:
            if not graph_store.graph.has_node(entity_id):
                missing_entities.append(entity_id)
        
        if missing_entities:
            return {
                'success': False,
                'error': f'The following entities do not exist: {missing_entities}'
            }
        
        # Collect all properties from entities being consolidated
        consolidated_properties = properties or {}
        all_descriptions = []
        
        for entity_id in entity_ids:
            entity_data = graph_store.get_entity(entity_id)
            if entity_data:
                # Merge properties (new properties override old ones)
                for key, value in entity_data.items():
                    if key not in ['type', 'description', 'created_at', 'updated_at']:
                        if key not in consolidated_properties:
                            consolidated_properties[key] = value
                
                # Collect descriptions
                if entity_data.get('description'):
                    all_descriptions.append(entity_data['description'])
        
        # Use provided description or combine existing ones
        final_description = description
        if not final_description and all_descriptions:
            final_description = ' | '.join(all_descriptions)
        
        # Create or update the target entity
        success = graph_store.add_entity(
            target_entity,
            entity_type,
            consolidated_properties,
            final_description
        )
        
        if not success:
            return {
                'success': False,
                'error': 'Failed to create/update target entity'
            }
        
        # Update embedding for the new entity
        if final_description:
            embedding_manager.add_entity_embedding(target_entity, final_description)
        
        # Redirect all relationships
        relationships_updated = 0
        
        for entity_id in entity_ids:
            if entity_id == target_entity:
                continue  # Skip if consolidating into itself
            
            # Get all incoming edges
            incoming_edges = list(graph_store.graph.in_edges(entity_id, data=True))
            for source, _, edge_data in incoming_edges:
                if source != target_entity:  # Avoid self-loops unless they existed
                    graph_store.add_relationship(
                        source,
                        target_entity,
                        edge_data.get('type', 'unknown'),
                        {k: v for k, v in edge_data.items() if k not in ['type', 'weight', 'created_at']},
                        edge_data.get('weight', 1.0)
                    )
                    relationships_updated += 1
            
            # Get all outgoing edges
            outgoing_edges = list(graph_store.graph.out_edges(entity_id, data=True))
            for _, target, edge_data in outgoing_edges:
                if target != target_entity:  # Avoid self-loops unless they existed
                    graph_store.add_relationship(
                        target_entity,
                        target,
                        edge_data.get('type', 'unknown'),
                        {k: v for k, v in edge_data.items() if k not in ['type', 'weight', 'created_at']},
                        edge_data.get('weight', 1.0)
                    )
                    relationships_updated += 1
        
        # Remove old entities
        removed_entities = []
        for entity_id in entity_ids:
            if entity_id != target_entity:  # Don't remove if consolidating into itself
                graph_store.graph.remove_node(entity_id)
                removed_entities.append(entity_id)
                
                # Remove embeddings for old entities
                try:
                    embedding_manager.remove_entity(entity_id)
                except:
                    pass  # Embedding might not exist
        
        # Save changes
        graph_store.save()
        embedding_manager.save()
        
        return {
            'success': True,
            'target_entity': target_entity,
            'consolidated_from': removed_entities,
            'relationships_updated': relationships_updated,
            'message': f'Successfully consolidated {len(removed_entities)} entities into "{target_entity}"'
        }
        
    except Exception as e:
        logger.error(f"Error consolidating entities: {e}")
        return {
            'success': False,
            'error': str(e)
        }