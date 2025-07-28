"""Knowledge Graph Query Engine using a YAML-based DSL - Refactored Version."""

import time
import logging
from typing import Dict, Any

from .graph_store import KnowledgeGraphStore
from .embeddings import EmbeddingManager
from .query import QueryParser, QueryCompiler, ResultFormatter

logger = logging.getLogger(__name__)

class KnowledgeGraphQueryEngine:
    """Parses and executes queries defined in a YAML DSL."""

    def __init__(self, graph_store: KnowledgeGraphStore, embedding_manager: EmbeddingManager):
        """
        Initialize the query engine.

        Args:
            graph_store: Instance of KnowledgeGraphStore.
            embedding_manager: Instance of EmbeddingManager.
        """
        self.graph_store = graph_store
        self.embeddings = embedding_manager
        
        # Initialize components
        self.parser = QueryParser()
        self.compiler = QueryCompiler(graph_store, embedding_manager)
        self.formatter = ResultFormatter(graph_store)

    def parse_yaml_query(self, query_yaml: str) -> Dict[str, Any]:
        """Parse a YAML query string into a dictionary."""
        return self.parser.parse_yaml_query(query_yaml)

    def compile_query(self, parsed_query: Dict[str, Any]):
        """Compile a parsed query into an executable function."""
        return self.compiler.compile_query(parsed_query)

    def execute_query(self, query_yaml: str) -> Dict[str, Any]:
        """Execute a YAML query and return results with metadata."""
        start_time = time.time()
        try:
            parsed = self.parse_yaml_query(query_yaml)
            compiled_query = self.compile_query(parsed)
            results = compiled_query()
            execution_time = time.time() - start_time
            
            return self.formatter.format_query_response(
                success=True,
                query_name=parsed['name'],
                query_type=parsed['type'],
                results=results,
                execution_time=execution_time
            )
        except Exception as e:
            execution_time = time.time() - start_time
            logger.error(f"Query execution failed: {e}", exc_info=True)
            return self.formatter.format_query_response(
                success=False,
                query_name="unknown",
                query_type="unknown",
                results=None,
                execution_time=execution_time,
                error=str(e)
            )