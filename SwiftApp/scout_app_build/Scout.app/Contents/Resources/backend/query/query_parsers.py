"""Query parsing utilities for the knowledge graph query engine."""

import yaml
import logging
from typing import Dict, Any

logger = logging.getLogger(__name__)

class QueryParser:
    """Handles parsing of YAML queries into structured data."""
    
    @staticmethod
    def parse_yaml_query(query_yaml: str) -> Dict[str, Any]:
        """Parse a YAML query string into a dictionary."""
        try:
            query_data = yaml.safe_load(query_yaml)
            # The query is expected to be the first (and only) key in the YAML
            query_name = next(iter(query_data))
            query_spec = query_data[query_name]
            
            query_type = next(iter(query_spec))
            query_def = query_spec[query_type]

            return {
                'name': query_name,
                'type': query_type,
                'definition': query_def
            }
        except (yaml.YAMLError, StopIteration) as e:
            logger.error(f"Failed to parse YAML query: {e}")
            raise ValueError(f"Invalid YAML query format: {e}")
    
    @staticmethod
    def validate_query_structure(parsed_query: Dict[str, Any]) -> bool:
        """Validate that a parsed query has the required structure."""
        required_keys = ['name', 'type', 'definition']
        return all(key in parsed_query for key in required_keys)
    
    @staticmethod
    def extract_nodes_definition(query_def: Dict[str, Any]) -> Dict[str, Any]:
        """Extract nodes section from query definition."""
        if "nodes" in query_def:
            return query_def["nodes"]
        else:
            return query_def
    
    @staticmethod
    def extract_return_specification(nodes_def: Dict[str, Any]) -> list:
        """Extract return specification from nodes definition."""
        return nodes_def.get('return', ['name', 'type'])
