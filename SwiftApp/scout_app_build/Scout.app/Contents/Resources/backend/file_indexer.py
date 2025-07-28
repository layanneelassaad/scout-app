"""Refactored file indexing for the Knowledge Graph plugin."""

import os
import sys
import json
import logging
from datetime import datetime
from typing import Dict, List, Any, Optional

from .graph_store import KnowledgeGraphStore
from .embeddings import EmbeddingManager
from .entity_types import ContactManager
from .contact_context import ContactContextManager
from .file_operations import FileOperations
from .content_processor import ContentProcessor
from .entity_analyzer import EntityAnalyzer

logger = logging.getLogger(__name__)

class FileIndexer:
    """Refactored file indexer with modular design and whole-file analysis."""

    def __init__(self, 
                 graph_store: KnowledgeGraphStore, 
                 embedding_manager: EmbeddingManager):
        """
        Initialize the FileIndexer.

        Args:
            graph_store: Instance of KnowledgeGraphStore.
            embedding_manager: Instance of EmbeddingManager.
        """
        self.graph_store = graph_store
        self.embedding_manager = embedding_manager
        
        self.storage_path = os.path.join(graph_store.storage_path, 'file_index')
        self.indexed_files_path = os.path.join(self.storage_path, 'indexed_files.json')
        os.makedirs(self.storage_path, exist_ok=True)
        
        self.indexed_files = self._load_indexed_files()
        
        # Initialize managers
        self.contact_manager = ContactManager(self.storage_path)
        self.contact_context_manager = ContactContextManager(self.graph_store)
        
        # Initialize processors
        self.file_ops = FileOperations()
        self.content_processor = ContentProcessor()
        self.entity_analyzer = EntityAnalyzer(self.contact_context_manager)

    def _load_indexed_files(self) -> Dict[str, Any]:
        """Load the dictionary of indexed files from disk."""
        if os.path.exists(self.indexed_files_path):
            try:
                with open(self.indexed_files_path, 'r') as f:
                    return json.load(f)
            except (json.JSONDecodeError, IOError) as e:
                logger.error(f"Could not load indexed files list: {e}")
        return {}

    def _save_indexed_files(self):
        """Save the dictionary of indexed files to disk."""
        temp_path = self.indexed_files_path + '.tmp'
        try:
            with open(temp_path, 'w') as f:
                json.dump(self.indexed_files, f, indent=2, default=str)
            os.rename(temp_path, self.indexed_files_path)
        except (IOError, json.JSONDecodeError) as e:
            logger.error(f"Could not save indexed files list: {e}")
            if os.path.exists(temp_path):
                try:
                    os.remove(temp_path)
                except OSError:
                    pass

    def _create_file_entity(self, file_path: str, metadata: Dict[str, Any]) -> str:
        """Create a File entity in the graph."""
        file_name = metadata.get('file_name', os.path.basename(file_path))
        
        # Create file entity
        file_entity_name = f"File:{file_name}"
        
        description = f"File: {file_name} located at {file_path}"
        if metadata.get('file_extension'):
            description += f" (Type: {metadata['file_extension']})"
        
        self.graph_store.add_entity(
            name=file_entity_name,
            entity_type='File',
            properties=metadata,
            description=description
        )
        
        # Add embedding for file name and path for searchability
        search_text = f"{file_name} {file_path} {metadata.get('file_extension', '')}"
        self.embedding_manager.add_entity_embedding(file_entity_name, search_text)
        
        return file_entity_name

    def _remove_old_file_entries(self, file_path: str):
        """Remove any existing entries for a file path (used when file is modified)."""
        to_remove = []
        for file_hash, file_data in self.indexed_files.items():
            if file_data.get('path') == file_path:
                to_remove.append(file_hash)
        
        for hash_to_remove in to_remove:
            logger.debug(f"Removing old index entry for {file_path} with hash {hash_to_remove}")
            del self.indexed_files[hash_to_remove]
        
        if to_remove:
            self._save_indexed_files()

    def _create_text_chunks(self, content: str, file_path: str, file_metadata: Dict[str, Any], 
                          file_entity_name: str, chunk_size: int = 2000, overlap: int = 200) -> int:
        """Create text chunk entities and link them to the file."""
        chunks = self.content_processor.chunk_text(content, chunk_size, overlap)
        
        for i, chunk in enumerate(chunks):
            chunk_id = f"{file_path}::chunk_{i}"
            
            # Create text chunk entity
            self.graph_store.add_entity(
                name=chunk_id, 
                entity_type='TextChunk',
                properties={
                    'source_file': file_path, 
                    'chunk_index': i,
                    'word_count': len(chunk.split()),
                    'file_name': file_metadata.get('file_name', '')
                },
                description=chunk
            )
            self.embedding_manager.add_entity_embedding(chunk_id, chunk)
            
            # Link chunk to file
            self.graph_store.add_relationship(file_entity_name, chunk_id, 'contains_chunk')
        
        return len(chunks)

    async def index_file(self, file_path: str, chunk_size: int = 2000, overlap: int = 200, 
                        extract_entities: bool = True, auto_analyze: bool = True) -> Dict[str, Any]:
        """Index a file with whole-file analysis approach.
        
        Args:
            file_path: Path to the file to index
            chunk_size: Size of text chunks (default increased to 2000)
            overlap: Overlap between chunks (default increased to 200)
            extract_entities: Whether to extract entities
            auto_analyze: Whether to use AI analysis
        """
        if not os.path.exists(file_path):
            return {'success': False, 'error': 'File not found'}

        file_hash = self.file_ops.calculate_file_hash(file_path)
        if not file_hash:
            return {'success': False, 'error': 'Could not read file to calculate hash'}

        # Check if file is already indexed with current hash
        if self.is_file_indexed(file_path, file_hash):
            logger.debug(f"File {file_path} already indexed with hash {file_hash}, skipping")
            return {'success': True, 'status': 'skipped', 'message': 'File already indexed and unchanged.'}
        
        # Remove any old entries for this file path
        self._remove_old_file_entries(file_path)

        logger.info(f"Indexing file: {file_path}")
        
        # Extract file metadata
        file_metadata = self.file_ops.extract_file_metadata(file_path)
        
        # Create File entity
        file_entity_name = self._create_file_entity(file_path, file_metadata)
        
        # Read content (limit to 40KB for analysis)
        content = self.file_ops.read_file_content(file_path)
        if not content:
            # Still create file entity even if content can't be read
            self.indexed_files[file_hash] = {
                'path': file_path, 'indexed_at': datetime.now().isoformat(), 'hash': file_hash,
                'chunks': 0, 'entities_extracted': 0, 'relations_extracted': 0,
                'file_entity': file_entity_name, 'content_readable': False
            }
            self._save_indexed_files()
            return {'success': True, 'status': 'indexed', 'file_path': file_path,
                   'chunks_created': 0, 'entities_added': 0, 'relations_added': 0,
                   'note': 'File entity created but content could not be read'}

        # Create text chunks for searchability
        chunks_created = self._create_text_chunks(content, file_path, file_metadata, file_entity_name, chunk_size, overlap)
        
        total_entities_added = 0
        total_relations_added = 0
        
        # NEW APPROACH: Analyze whole file content (limited to 40KB) instead of per-chunk
        if extract_entities and auto_analyze:
            # Prepare content for analysis (limit to 40KB)
            analysis_content = self.content_processor.prepare_analysis_content(content, max_chars=40000)
            print('///////////////////////////////////////////////////////////')
            print('')
            print('')
            print('analysis_content',analysis_content)
            print('///////////////////////////////////////////////////////////')
            print()
            if analysis_content:
                analysis_result = await self.entity_analyzer.analyze_file_content(
                    analysis_content, file_metadata, file_entity_name
                )
                print('.......................................')
                print('analysis_result:',analysis_result)
                if analysis_result:
                    # Process entities from whole-file analysis
                    for entity in analysis_result.get('entities', []):
                        # Merge properties if provided
                        entity_properties = entity.get('properties', {})
                        
                        if self.graph_store.add_entity(
                            name=entity['name'], 
                            entity_type=entity['type'], 
                            properties=entity_properties,
                            description=entity.get('description')
                        ):
                            total_entities_added += 1
                            # Link entity to file (not individual chunks)
                            self.graph_store.add_relationship(file_entity_name, entity['name'], 'mentions')
                            
                            # Add to legacy contact manager for compatibility
                            if entity.get('type') == 'Person':
                                self.contact_manager.add_contact(
                                    entity['name'],
                                    {'description': entity.get('description', ''), **entity_properties}
                                )
                    
                    # Process relationships from whole-file analysis
                    for rel in analysis_result.get('relationships', []):
                        if self.graph_store.add_relationship(rel['source'], rel['target'], rel['type']):
                            total_relations_added += 1

        # Record indexing operation
        self.indexed_files[file_hash] = {
            'path': file_path, 'indexed_at': datetime.now().isoformat(), 'hash': file_hash,
            'chunks': chunks_created, 'entities_extracted': total_entities_added,
            'relations_extracted': total_relations_added, 'file_entity': file_entity_name,
            'content_readable': True, 'analysis_approach': 'whole_file'
        }
        self._save_indexed_files()
        
        # Save graph and embeddings
        self.graph_store.save()
        self.embedding_manager.save()
        return {
            'success': True, 'status': 'indexed', 'file_path': file_path,
            'chunks_created': chunks_created, 'entities_added': total_entities_added,
            'relations_added': total_relations_added, 'file_entity': file_entity_name,
            'analysis_approach': 'whole_file'
        }

    def is_file_indexed(self, file_path: str, file_hash: Optional[str] = None) -> bool:
        """Check if a file is already indexed and its content is unchanged."""
        if file_hash is None:
            file_hash = self.file_ops.calculate_file_hash(file_path)
        return file_hash in self.indexed_files

    def get_indexed_file_info(self, file_path: str) -> Optional[Dict[str, Any]]:
        """Get metadata for an indexed file."""
        file_hash = self.file_ops.calculate_file_hash(file_path)
        return self.indexed_files.get(file_hash)

    def list_indexed_files(self) -> List[Dict[str, Any]]:
        """List all indexed files."""
        return list(self.indexed_files.values())

    async def reindex_file(self, file_path: str, **kwargs) -> Dict[str, Any]:
        """Force reindexing of a file by removing old data and re-running."""
        # Find and remove the old entry based on file path
        old_hash_to_remove = None
        for file_hash, file_data in self.indexed_files.items():
            if file_data.get('path') == file_path:
                old_hash_to_remove = file_hash
                break
        
        if old_hash_to_remove:
            del self.indexed_files[old_hash_to_remove]
        
        return await self.index_file(file_path, **kwargs)