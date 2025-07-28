"""Knowledge Graph data storage and management using NetworkX."""

import os
import json
import logging
import re
from datetime import datetime
from typing import Dict, List, Any, Optional, Set
from builtins import open

import networkx as nx
import pandas as pd

logger = logging.getLogger(__name__)

class KnowledgeGraphStore:
    """Manages the storage and retrieval of the knowledge graph."""

    def __init__(self, storage_path: str):
        """
        Initialize the graph store.

        Args:
            storage_path: Directory to store graph data.
        """
        self.storage_path = storage_path
        self.graph_file = os.path.join(storage_path, 'knowledge_graph.json')
        os.makedirs(self.storage_path, exist_ok=True)
        
        self.graph = nx.MultiDiGraph()
        self._load_graph()

    def _load_graph(self):
        """Load graph from a JSON file."""
        if os.path.exists(self.graph_file):
            try:
                with open(self.graph_file, 'r') as f:
                    data = json.load(f)
                    self.graph = nx.node_link_graph(data, directed=True, multigraph=True)
                logger.info(f"Knowledge graph loaded from {self.graph_file}")
            except Exception as e:
                logger.error(f"Failed to load graph: {e}")
                self.graph = nx.MultiDiGraph()
        else:
            logger.info("No existing graph found. Starting fresh.")

    def _save_graph(self):
        """Save the current graph to a JSON file."""
        try:
            with open(self.graph_file, 'w') as f:
                data = nx.node_link_data(self.graph)
                json.dump(data, f, indent=2, default=str)
            logger.info(f"Knowledge graph saved to {self.graph_file}")
        except Exception as e:
            logger.error(f"Failed to save graph: {e}")

    def _validate_entity_name(self, name: str, entity_type: str) -> str:
        """Validate and clean entity names to prevent duplicates."""
        if not name or not isinstance(name, str):
            raise ValueError("Entity name must be a non-empty string")
        
        # Strip whitespace
        cleaned_name = name.strip()
        
        # For Person entities, check for and remove brackets
        if entity_type == 'Person':
            # Check if name contains brackets
            if '[' in cleaned_name or ']' in cleaned_name:
                # Strip all brackets from the beginning and end
                original = cleaned_name
                while cleaned_name.startswith('[') and cleaned_name.endswith(']'):
                    cleaned_name = cleaned_name[1:-1].strip()
                
                logger.warning(f"Removed brackets from Person entity name: '{original}' -> '{cleaned_name}'")
                
                # If the cleaned name already exists in the graph, don't create a duplicate
                if self.graph.has_node(cleaned_name):
                    existing_data = self.graph.nodes[cleaned_name]
                    if existing_data.get('type') == 'Person':
                        logger.info(f"Using existing Person entity '{cleaned_name}' instead of creating duplicate with brackets")
                        return cleaned_name
        
        return cleaned_name

    def add_entity(self, name: str, entity_type: str, properties: Optional[Dict] = None, description: Optional[str] = None) -> bool:
        """Add or update an entity in the graph."""
        if not entity_type:
            return False
        
        try:
            # Validate and clean the entity name
            cleaned_name = self._validate_entity_name(name, entity_type)
            
            properties = properties or {}
            node_data = {
                'type': entity_type,
                'description': description or '',
                'created_at': datetime.now().isoformat(),
                **properties
            }
            
            # Check if this is an update to an existing entity
            if self.graph.has_node(cleaned_name):
                existing_data = self.graph.nodes[cleaned_name]
                if existing_data.get('type') == entity_type:
                    # Update existing entity, preserving created_at
                    node_data['created_at'] = existing_data.get('created_at', node_data['created_at'])
                    node_data['updated_at'] = datetime.now().isoformat()
            
            self.graph.add_node(cleaned_name, **node_data)
            return True
            
        except ValueError as e:
            logger.error(f"Invalid entity name: {e}")
            return False

    def get_entity(self, name: str) -> Optional[Dict[str, Any]]:
        """Retrieve an entity's data."""
        if self.graph.has_node(name):
            return self.graph.nodes[name]
        return None

    def add_relationship(self, from_entity: str, to_entity: str, relation_type: str, properties: Optional[Dict] = None, weight: float = 1.0) -> bool:
        """Add a relationship between two entities."""
        if not all([from_entity, to_entity, relation_type]):
            return False
        
        # Clean entity names (strip brackets if present)
        from_entity = from_entity.strip()
        to_entity = to_entity.strip()
        
        # Try to find entities without brackets if they don't exist
        if not self.graph.has_node(from_entity):
            cleaned_from = from_entity
            while cleaned_from.startswith('[') and cleaned_from.endswith(']'):
                cleaned_from = cleaned_from[1:-1].strip()
            if cleaned_from != from_entity and self.graph.has_node(cleaned_from):
                logger.info(f"Using cleaned entity name '{cleaned_from}' instead of '{from_entity}' for relationship source")
                from_entity = cleaned_from
        
        if not self.graph.has_node(to_entity):
            cleaned_to = to_entity
            while cleaned_to.startswith('[') and cleaned_to.endswith(']'):
                cleaned_to = cleaned_to[1:-1].strip()
            if cleaned_to != to_entity and self.graph.has_node(cleaned_to):
                logger.info(f"Using cleaned entity name '{cleaned_to}' instead of '{to_entity}' for relationship target")
                to_entity = cleaned_to
        
        if not self.graph.has_node(from_entity) or not self.graph.has_node(to_entity):
            return False
        
        properties = properties or {}
        edge_data = {
            'type': relation_type,
            'weight': weight,
            'created_at': datetime.now().isoformat(),
            **properties
        }
        
        self.graph.add_edge(from_entity, to_entity, **edge_data)
        return True

    def find_connected_entities(self, start_entity: str, max_depth: int = 2, relation_types: Optional[List[str]] = None, direction: str = "both") -> List[str]:
        """Find all entities connected to a starting entity within a certain depth."""
        if not self.graph.has_node(start_entity):
            return []
        
        visited: Set[str] = {start_entity}
        queue = [(start_entity, 0)]
        connected_nodes: List[str] = []

        while queue:
            current_node, depth = queue.pop(0)
            if depth >= max_depth:
                continue

            # Get neighbors based on direction
            if direction == "outgoing":
                neighbors = self.graph.successors(current_node)
            elif direction == "incoming":
                neighbors = self.graph.predecessors(current_node)
            elif direction == "both":
                # Combine both incoming and outgoing neighbors
                neighbors = set(self.graph.successors(current_node)) | set(self.graph.predecessors(current_node))
            else:
                raise ValueError(f"Invalid direction: {direction}. Must be 'outgoing', 'incoming', or 'both'")

            for neighbor in neighbors:
                if neighbor not in visited:
                    # Check if the relationship type is allowed
                    if relation_types:
                        # FIXED: Check edges in both directions when direction="both"
                        edge_found = False
                        
                        # Check outgoing edge
                        edges_out = self.graph.get_edge_data(current_node, neighbor)
                        if edges_out and any(edge_data.get('type') in relation_types for edge_data in edges_out.values()):
                            edge_found = True
                        
                        # Check incoming edge (if direction is "both")
                        if not edge_found and direction == "both":
                            edges_in = self.graph.get_edge_data(neighbor, current_node)
                            if edges_in and any(edge_data.get('type') in relation_types for edge_data in edges_in.values()):
                                edge_found = True
                        
                        if edge_found:
                            visited.add(neighbor)
                            queue.append((neighbor, depth + 1))
                            connected_nodes.append(neighbor)
                    else:
                        visited.add(neighbor)
                        queue.append((neighbor, depth + 1))
                        connected_nodes.append(neighbor)
        
        return connected_nodes
    def get_entities_by_type(self, entity_type: str) -> List[tuple[str, Dict[str, Any]]]:
        """Get all entities of a specific type."""
        results = []
        for node, data in self.graph.nodes(data=True):
            if data.get("type") == entity_type:
                results.append((node, data))
        return results
    
    def get_all_entity_types(self) -> List[str]:
        """Get a list of all unique entity types in the graph."""
        types = set()
        for node, data in self.graph.nodes(data=True):
            entity_type = data.get("type")
            if entity_type:
                types.add(entity_type)
        return sorted(list(types))

    def get_subgraph(self, entities: List[str]) -> nx.MultiDiGraph:
        """Return a subgraph containing only the specified entities."""
        return self.graph.subgraph(entities)

    def search_entities(self, query: str) -> List[tuple[str, Dict[str, Any]]]:
        """Perform a simple text search on entity names and descriptions."""
        results = []
        query_lower = query.lower()
        for node, data in self.graph.nodes(data=True):
            if query_lower in node.lower() or query_lower in data.get('description', '').lower():
                results.append((node, data))
        return results

    def get_statistics(self) -> Dict[str, int]:
        """Get basic statistics about the graph."""
        return {
            'num_entities': self.graph.number_of_nodes(),
            'num_relationships': self.graph.number_of_edges()
        }

    def export_to_format(self, format_type: str, output_path: str) -> bool:
        """Export the graph to various formats."""
        try:
            if format_type.lower() == 'json':
                with open(output_path, 'w') as f:
                    data = nx.node_link_data(self.graph)
                    json.dump(data, f, indent=2, default=str)
            
            elif format_type.lower() == 'graphml':
                nx.write_graphml(self.graph, output_path)
            
            elif format_type.lower() == 'gexf':
                nx.write_gexf(self.graph, output_path)
            
            elif format_type.lower() == 'csv':
                base_path = output_path.rsplit('.', 1)[0]
                
                nodes_data = []
                for node, data in self.graph.nodes(data=True):
                    row = {'id': node, **data}
                    nodes_data.append(row)
                pd.DataFrame(nodes_data).to_csv(f"{base_path}_nodes.csv", index=False)
                
                edges_data = []
                for source, target, data in self.graph.edges(data=True):
                    row = {'source': source, 'target': target, **data}
                    edges_data.append(row)
                pd.DataFrame(edges_data).to_csv(f"{base_path}_edges.csv", index=False)
            
            else:
                raise ValueError(f"Unsupported format: {format_type}")
            
            logger.info(f"Graph exported to {output_path} in {format_type} format")
            return True
            
        except Exception as e:
            logger.error(f"Failed to export graph: {e}")
            return False

    def import_from_format(self, format_type: str, input_path: str) -> bool:
        """Import graph from various formats."""
        try:
            if format_type.lower() == 'json':
                with open(input_path, 'r') as f:
                    data = json.load(f)
                self.graph = nx.node_link_graph(data, directed=True, multigraph=True)
            
            elif format_type.lower() == 'graphml':
                self.graph = nx.read_graphml(input_path)
            
            elif format_type.lower() == 'gexf':
                self.graph = nx.read_gexf(input_path)
            
            else:
                raise ValueError(f"Unsupported format: {format_type}")
            
            if not isinstance(self.graph, nx.MultiDiGraph):
                self.graph = nx.MultiDiGraph(self.graph)

            logger.info(f"Graph imported from {input_path} ({format_type} format)")
            return True
            
        except Exception as e:
            logger.error(f"Failed to import graph: {e}")
            return False

    def save(self):
        """Save the current graph state."""
        self._save_graph()

    def __del__(self):
        """Ensure graph is saved on object destruction."""
        try:
            self._save_graph()
        except Exception:
            pass # Suppress errors during cleanup