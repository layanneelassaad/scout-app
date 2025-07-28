"""Result formatting utilities for the knowledge graph query engine."""

import logging
from typing import Dict, List, Any

logger = logging.getLogger(__name__)

class ResultFormatter:
    """Handles formatting of query results."""
    
    def __init__(self, graph_store):
        self.graph_store = graph_store
    
    def format_node_results(self, candidates: List[str], return_spec: List[str]) -> List[Dict[str, Any]]:
        """Format node candidates into result dictionaries."""
        results = []
        for node_name in candidates:
            node_data = self.graph_store.get_entity(node_name)
            if node_data:
                result = {'name': node_name}
                for field in return_spec:
                    if field != 'name':
                        result[field] = node_data.get(field)
                results.append(result)
        return results
    
    def format_path_results(self, paths: List[List[str]], include_semantic_scores: bool = False) -> List[Dict[str, Any]]:
        """Format path results."""
        results = []
        for path in paths:
            path_data = {
                'path': path,
                'length': len(path) - 1
            }
            if include_semantic_scores:
                # This would need to be calculated by the compiler
                path_data['semantic_coherence'] = []
            results.append(path_data)
        return results
    
    def format_query_response(self, success: bool, query_name: str, query_type: str, 
                            results: Any, execution_time: float, error: str = None) -> Dict[str, Any]:
        """Format the complete query response."""
        response = {
            'success': success,
            'query_name': query_name,
            'query_type': query_type,
            'execution_time': round(execution_time, 4)
        }
        
        if success:
            response['results'] = results
            response['result_count'] = len(results) if isinstance(results, list) else 1
        else:
            response['error'] = error
        
        return response
