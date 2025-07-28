"""MindRoot Knowledge Graph Plugin - Core infrastructure with enhanced features."""

import os
import logging
from typing import Set

from .graph_store import KnowledgeGraphStore
from .embeddings import EmbeddingManager
from .query_engine import KnowledgeGraphQueryEngine
from .file_indexer import FileIndexer
from .entity_types import ContactManager

logger = logging.getLogger(__name__)

# Global state to prevent concurrent indexing
_indexing_in_progress: Set[str] = set()  # Set of paths currently being indexed

# Global instances (initialized on first use)
_graph_store = None
_embedding_manager = None
_query_engine = None
_file_indexer = None
_contact_manager = None

def get_indexing_in_progress():
    """Get the set of paths currently being indexed."""
    return _indexing_in_progress

def _get_graph_store():
    """Get or create graph store instance."""
    global _graph_store
    if _graph_store is None:
        storage_path = os.path.expanduser("~/.mr_kg_data")
        _graph_store = KnowledgeGraphStore(storage_path)
    return _graph_store

def _get_embedding_manager():
    """Get or create embedding manager instance."""
    global _embedding_manager
    if _embedding_manager is None:
        cache_dir = os.path.expanduser("~/.mr_kg_cache")
        _embedding_manager = EmbeddingManager(cache_dir=cache_dir)
    return _embedding_manager

def _get_query_engine():
    """Get or create query engine instance."""
    global _query_engine
    if _query_engine is None:
        _query_engine = KnowledgeGraphQueryEngine(
            _get_graph_store(),
            _get_embedding_manager()
        )
    return _query_engine

def _get_file_indexer():
    """Get or create file indexer instance."""
    global _file_indexer
    if _file_indexer is None:
        _file_indexer = FileIndexer(
            _get_graph_store(),
            _get_embedding_manager()
        )
    return _file_indexer

def _get_contact_manager():
    """Get or create contact manager instance."""
    global _contact_manager
    if _contact_manager is None:
        storage_path = os.path.expanduser("~/.mr_kg_data")
        _contact_manager = ContactManager(storage_path)
    return _contact_manager

# Export the getter functions for use by commands
__all__ = [
    'get_indexing_in_progress',
    '_get_graph_store',
    '_get_embedding_manager', 
    '_get_query_engine',
    '_get_file_indexer',
    '_get_contact_manager'
]