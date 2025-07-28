"""Enhanced Query compilation utilities with sorting and limiting support."""

import numpy as np
import logging
from typing import Dict, List, Any, Callable, Union
from datetime import datetime
from functools import cmp_to_key

from .query_parsers import QueryParser
from .filter_processors import FilterProcessor
from .result_formatters import ResultFormatter

logger = logging.getLogger(__name__)

class QueryCompiler:
    """Compiles parsed queries into executable functions with sorting and limiting support."""
    
    def __init__(self, graph_store, embedding_manager=None):
        self.graph_store = graph_store
        self.embeddings = embedding_manager
        self.filter_processor = FilterProcessor(graph_store, embedding_manager)
        self.result_formatter = ResultFormatter(graph_store)
        self.query_parser = QueryParser()
    
    def compile_query(self, parsed_query: Dict[str, Any]) -> Callable[[], Any]:
        """Compile a parsed query into an executable function."""
        query_type = parsed_query['type']
        query_def = parsed_query['definition']

        if query_type == 'find_nodes':
            return self._compile_find_nodes_query(query_def)
        elif query_type == 'find_path':
            return self._compile_find_path_query(query_def)
        elif query_type == "find":
            return self._compile_find_query(query_def)
        else:
            raise ValueError(f"Unsupported query type: {query_type}")
    
    def _compile_find_query(self, query_def: Dict[str, Any]) -> Callable[[], Any]:
        """Compile a find query (supports nodes with connectivity)."""
        if "nodes" in query_def:
            return self._compile_find_nodes_query(query_def)
        else:
            raise ValueError("Find query must specify 'nodes' target")
    
    def _compile_find_path_query(self, query_def: Dict[str, Any]) -> Callable[[], Any]:
        """Compile a path-finding query."""
        def execute() -> List[Dict[str, Any]]:
            from_node = query_def.get('from')
            to_node = query_def.get('to')
            max_hops = query_def.get('max_hops', 5)
            
            if not from_node or not to_node:
                raise ValueError("'from' and 'to' nodes must be specified for path finding.")

            paths = self.graph_store.find_shortest_path(from_node, to_node, max_hops)
            
            results = []
            for path in paths:
                path_data = {
                    'path': path,
                    'length': len(path) - 1,
                    'semantic_coherence': self._calculate_path_semantic_scores(path)
                }
                results.append(path_data)
            
            results = self._apply_sorting_and_limiting(results, query_def)
            return results
        return execute
    
    def _compile_find_nodes_query(self, query_def: Dict[str, Any]) -> Callable[[], Any]:
        """Compile a node-finding query with connectivity support."""
        def execute() -> Union[Dict[str, Any], List[Dict[str, Any]]]:
            nodes_def = self.query_parser.extract_nodes_definition(query_def)
            
            relations = query_def.get('relations')
            depth = query_def.get('depth', 2)
            return_spec = query_def.get('return', ['name', 'type'])
            
            if relations is not None or 'depth' in query_def:
                return self._execute_connectivity_query(nodes_def, relations, depth, return_spec, query_def)
            else:
                return self._execute_node_filter_query(nodes_def, query_def)
        
        return execute
    
    def _execute_connectivity_query(self, nodes_def: Dict[str, Any], relations: List[str], depth: int, return_spec: List[str], query_def: Dict[str, Any]) -> Dict[str, Any]:
        """Execute a connectivity-based query."""
        starting_candidates = list(self.graph_store.graph.nodes())
        starting_nodes = self._apply_all_filters(starting_candidates, nodes_def, query_def)
        
        if not starting_nodes:
            return {'nodes': [], 'edges': [], 'starting_nodes': [], 'connected_nodes': []}
        
        all_connected = set()
        all_nodes = set(starting_nodes)
        
        for start_node in starting_nodes:
            connected = self.graph_store.find_connected_entities(start_node, max_depth=depth, relation_types=relations, direction="both")
            all_connected.update(connected)
            all_nodes.update(connected)
        
        subgraph = self.graph_store.get_subgraph(list(all_nodes))
        
        formatted_nodes = []
        for node_name in all_nodes:
            node_data = self.graph_store.get_entity(node_name)
            if node_data:
                result = {'name': node_name}
                for field in return_spec:
                    if field != 'name':
                        if field == 'type':
                            result[field] = node_data.get('type')
                        elif field == 'description':
                            result[field] = node_data.get('description')
                        elif field == 'properties':
                            props = {k: v for k, v in node_data.items() if k not in ['type', 'description', 'created_at', 'updated_at']}
                            result[field] = props
                        else:
                            result[field] = node_data.get(field)
                formatted_nodes.append(result)
        
        formatted_nodes = self._apply_sorting_and_limiting(formatted_nodes, query_def)
        
        formatted_edges = []
        for source, target, edge_data in subgraph.edges(data=True):
            edge_result = {'source': source, 'target': target, 'type': edge_data.get('type', 'Unknown'), 'weight': edge_data.get('weight', 1.0)}
            edge_props = {k: v for k, v in edge_data.items() if k not in ['type', 'weight', 'created_at']}
            if edge_props:
                edge_result['properties'] = edge_props
            formatted_edges.append(edge_result)
        
        return {'nodes': formatted_nodes, 'edges': formatted_edges, 'starting_nodes': starting_nodes, 'connected_nodes': list(all_connected), 'node_count': len(formatted_nodes), 'edge_count': len(formatted_edges)}
    
    def _execute_node_filter_query(self, nodes_def: Dict[str, Any], query_def: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Execute a regular node filtering query."""
        candidates = list(self.graph_store.graph.nodes())
        candidates = self._apply_all_filters(candidates, nodes_def, query_def)
        
        return_spec = self.query_parser.extract_return_specification(nodes_def)
        results = self.result_formatter.format_node_results(candidates, return_spec)
        
        results = self._apply_sorting_and_limiting(results, query_def)
        return results
    
    def _apply_sorting_and_limiting(self, results: List[Dict[str, Any]], query_def: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Apply sorting and limiting to query results."""
        if not results:
            return results
        
        order_by = query_def.get('order_by')
        if order_by:
            results = self._sort_results(results, order_by, query_def.get('order', 'asc'))
        
        limit = query_def.get('limit')
        if limit and isinstance(limit, int) and limit > 0:
            results = results[:limit]
        
        return results
    
    def _sort_results(self, results: List[Dict[str, Any]], order_by: Union[str, List[Dict[str, str]]], default_order: str = 'asc') -> List[Dict[str, Any]]:
        """Sort results based on order_by specification."""
        if not results:
            return results
        
        try:
            if isinstance(order_by, str):
                return self._sort_by_single_field(results, order_by, default_order)
            elif isinstance(order_by, list):
                return self._sort_by_multiple_fields(results, order_by)
            else:
                logger.warning(f"Invalid order_by format: {order_by}")
                return results
        except Exception as e:
            logger.error(f"Error sorting results: {e}")
            return results
    
    def _sort_by_single_field(self, results: List[Dict[str, Any]], field: str, direction: str = 'asc') -> List[Dict[str, Any]]:
        """Sort results by a single field."""
        reverse = direction.lower() == 'desc'
        
        def get_sort_key(item: Dict[str, Any]):
            value = item.get(field)
            return self._normalize_sort_value(value)
        
        return sorted(results, key=get_sort_key, reverse=reverse)
    
    def _sort_by_multiple_fields(self, results: List[Dict[str, Any]], sort_specs: List[Dict[str, str]]) -> List[Dict[str, Any]]:
        """Sort results by multiple fields with different directions."""
        def compare_items(item1: Dict[str, Any], item2: Dict[str, Any]) -> int:
            for spec in sort_specs:
                field = spec.get('field')
                direction = spec.get('direction', 'asc')
                
                val1 = self._normalize_sort_value(item1.get(field))
                val2 = self._normalize_sort_value(item2.get(field))
                
                if val1 < val2:
                    result = -1
                elif val1 > val2:
                    result = 1
                else:
                    continue
                
                return result if direction.lower() == 'asc' else -result
            
            return 0
        
        return sorted(results, key=cmp_to_key(compare_items))
    
    def _normalize_sort_value(self, value: Any) -> Any:
        """Normalize a value for sorting purposes."""
        if value is None:
            return ''
        
        if isinstance(value, str):
            if self._is_datetime_string(value):
                try:
                    return datetime.fromisoformat(value.replace('Z', '+00:00'))
                except:
                    return value.lower()
            return value.lower()
        
        if isinstance(value, (int, float)):
            return value
        
        if isinstance(value, dict):
            return str(value).lower()
        
        if isinstance(value, list):
            return len(value) if value else 0
        
        return str(value).lower()
    
    def _is_datetime_string(self, value: str) -> bool:
        """Check if a string looks like a datetime."""
        if not isinstance(value, str):
            return False
        return 'T' in value or ('-' in value and ':' in value)
    
    def _apply_all_filters(self, candidates: List[str], nodes_def: Dict[str, Any], query_def: Dict[str, Any]) -> List[str]:
        """Apply all filtering steps in the correct order."""
        entity_type = nodes_def.get("type")
        if entity_type:
            candidates = self.filter_processor.filter_by_type(candidates, entity_type)
        
        name_filter = nodes_def.get("name")
        if name_filter:
            candidates = [c for c in candidates if c == name_filter]
        
        if "properties" in nodes_def:
            candidates = self.filter_processor.filter_by_properties(candidates, nodes_def["properties"])

        similar_to = nodes_def.get('similar_to')
        if similar_to:
            threshold_spec = self.filter_processor.parse_comparison(nodes_def.get('threshold', '> 0.5'))
            candidates = self.filter_processor.filter_by_semantic_similarity(candidates, similar_to, threshold_spec)

        for field_name, field_spec in nodes_def.items():
            if field_name in ["description"] and isinstance(field_spec, dict):
                candidates = self.filter_processor.filter_by_field_conditions(candidates, field_name, field_spec)

        filter_spec = query_def.get("filter")
        if filter_spec:
            candidates = self.filter_processor.apply_filter_conditions(candidates, filter_spec)

        where_spec = query_def.get('where')
        if where_spec:
            candidates = self.filter_processor.apply_where_conditions(candidates, where_spec)

        connected_to = query_def.get('connected_to')
        if connected_to:
            candidates = self.filter_processor.filter_by_connectivity(candidates, connected_to)

        if "properties" in query_def and "properties" not in nodes_def:
            candidates = self.filter_processor.filter_by_properties(candidates, query_def["properties"])
        
        return candidates
    
    def _calculate_path_semantic_scores(self, path: List[str]) -> List[float]:
        """Calculate semantic coherence scores for path segments."""
        scores = []
        if len(path) < 2 or not self.embeddings:
            return []

        for i in range(len(path) - 1):
            desc1 = self.graph_store.get_entity(path[i]).get('description', path[i])
            desc2 = self.graph_store.get_entity(path[i+1]).get('description', path[i+1])
            
            emb1 = self.embeddings.generate_embedding(desc1)
            emb2 = self.embeddings.generate_embedding(desc2)
            
            similarity = np.dot(emb1, emb2)
            scores.append(float(similarity))
        return scores
