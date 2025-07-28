"""Filter processing utilities for the knowledge graph query engine."""

import re
import numpy as np
import logging
from typing import Dict, List, Any, Optional, Union

from .condition_evaluators import ConditionEvaluator

logger = logging.getLogger(__name__)

class FilterProcessor:
    """Handles various types of filtering operations on node candidates."""
    
    def __init__(self, graph_store, embedding_manager=None):
        self.graph_store = graph_store
        self.embeddings = embedding_manager
        self.condition_evaluator = ConditionEvaluator()
    
    def filter_by_properties(self, candidates: List[str], properties_spec: Dict[str, Any]) -> List[str]:
        """Filter candidates by their properties with support for comparison operators."""
        filtered = []
        for candidate in candidates:
            node_data = self.graph_store.get_entity(candidate)
            if not node_data:
                continue
            
            matches = True
            for prop_name, prop_condition in properties_spec.items():
                if isinstance(prop_condition, dict):
                    condition_met = False
                    for operator, value in prop_condition.items():
                        if self.condition_evaluator.evaluate_property_condition(node_data, prop_name, operator, value):
                            condition_met = True
                            break
                    if not condition_met:
                        matches = False
                        break
                else:
                    if node_data.get(prop_name) != prop_condition:
                        matches = False
                        break
            
            if matches:
                filtered.append(candidate)
        return filtered
    
    def apply_where_conditions(self, candidates: List[str], where_spec: Any) -> List[str]:
        """Apply WHERE conditions to filter candidates."""
        filtered = []
        for candidate in candidates:
            node_data = self.graph_store.get_entity(candidate)
            if not node_data:
                continue
            
            if self.condition_evaluator.evaluate_condition(node_data, where_spec):
                filtered.append(candidate)
        return filtered
    
    def apply_filter_conditions(self, candidates: List[str], filter_spec: Dict[str, Any]) -> List[str]:
        """Apply filter conditions from a separate filter section."""
        filtered = []
        for candidate in candidates:
            node_data = self.graph_store.get_entity(candidate)
            if not node_data:
                continue
            
            matches = True
            for field_name, condition in filter_spec.items():
                if not self.condition_evaluator.evaluate_filter_field(node_data, field_name, condition):
                    matches = False
                    break
            
            if matches:
                filtered.append(candidate)
        
        return filtered
    
    def filter_by_connectivity(self, candidates: List[str], connectivity_spec: Dict[str, Any]) -> List[str]:
        """Filter candidates based on their connection to another entity."""
        entity = connectivity_spec.get('entity')
        if not entity:
            return candidates

        max_depth = connectivity_spec.get('max_depth', 2)
        relation_types = connectivity_spec.get('via')

        connected_entities = self.graph_store.find_connected_entities(
            entity, max_depth=max_depth, relation_types=relation_types
        )
        
        return [c for c in candidates if c in connected_entities]
    
    def filter_by_semantic_similarity(self, candidates: List[str], similar_to: str, threshold_spec: Dict[str, Any]) -> List[str]:
        """Filter candidates by semantic similarity based on a threshold."""
        if not self.embeddings:
            logger.warning("No embedding manager available for semantic filtering")
            return []

        try:
            target_embedding = self.embeddings.generate_embedding(similar_to)
        except Exception as e:
            logger.error(f"Could not generate embedding for '{similar_to}': {e}")
            return []

        operator = threshold_spec.get('operator', '>=')
        value = threshold_spec.get('value', 0.0)

        filtered_candidates = []
        for candidate in candidates:
            node_data = self.graph_store.get_entity(candidate)
            if not node_data:
                continue

            text_to_embed = node_data.get('description', candidate)
            
            try:
                candidate_embedding = self.embeddings.generate_embedding(text_to_embed)
                similarity = np.dot(target_embedding, candidate_embedding)
                
                if operator == '>=' and similarity >= value:
                    filtered_candidates.append(candidate)
                elif operator == '>' and similarity > value:
                    filtered_candidates.append(candidate)
                elif operator == '<=' and similarity <= value:
                    filtered_candidates.append(candidate)
                elif operator == '<' and similarity < value:
                    filtered_candidates.append(candidate)
                elif operator == '==' and similarity == value:
                    filtered_candidates.append(candidate)
                elif operator == '!=' and similarity != value:
                    filtered_candidates.append(candidate)
            except Exception as e:
                logger.warning(f"Could not process similarity for candidate '{candidate}': {e}")
        
        return filtered_candidates

    def filter_by_type(self, candidates: List[str], entity_type: str) -> List[str]:
        """Filter candidates by entity type."""
        type_filtered = []
        for candidate in candidates:
            node_data = self.graph_store.get_entity(candidate)
            if node_data and node_data.get("type") == entity_type:
                type_filtered.append(candidate)
        return type_filtered
    
    def filter_by_field_conditions(self, candidates: List[str], field_name: str, field_spec: Dict[str, Any]) -> List[str]:
        """Filter candidates by field-specific conditions."""
        field_filtered = []
        for candidate in candidates:
            node_data = self.graph_store.get_entity(candidate)
            if node_data and self.condition_evaluator.evaluate_field_condition(node_data, field_name, field_spec):
                field_filtered.append(candidate)
        return field_filtered
    
    def parse_comparison(self, comparison_spec: Union[str, float, int]) -> Dict[str, Any]:
        """
        Parse a comparison specification.
        
        Args:
            comparison_spec: Can be a string like '> 0.1', or a raw number.
            
        Returns:
            A dictionary like {'operator': '>', 'value': 0.1}.
            Defaults to '>=' if no operator is found.
        """
        if isinstance(comparison_spec, (float, int)):
            return {'operator': '>=', 'value': float(comparison_spec)}

        if not isinstance(comparison_spec, str):
            logger.warning(f"Invalid comparison spec type: {type(comparison_spec)}. Defaulting.")
            return {'operator': '>=', 'value': 0.0}

        match = re.match(r'^\s*(>=|<=|>|<|==|!=)\s*([-\d.]+)\s*$', comparison_spec)
        if match:
            return {'operator': match.group(1), 'value': float(match.group(2))}
        
        try:
            return {'operator': '>=', 'value': float(comparison_spec)}
        except ValueError:
            logger.warning(f"Could not parse comparison string: '{comparison_spec}'. Defaulting.")
            return {'operator': '>=', 'value': 0.0}
