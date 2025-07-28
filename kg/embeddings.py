"""Embedding management for knowledge graph with GPU/CPU support."""

import os
import numpy as np
import pickle
from typing import List, Dict, Tuple, Optional, Union
from sentence_transformers import SentenceTransformer
import logging
from builtins import open

try:
    import faiss
    FAISS_AVAILABLE = True
except ImportError:
    FAISS_AVAILABLE = False
    logging.warning("FAISS not available. Vector search will use sklearn fallback.")

from sklearn.metrics.pairwise import cosine_similarity
from sklearn.feature_extraction.text import TfidfVectorizer

logger = logging.getLogger(__name__)

class EmbeddingManager:
    """Manages text embeddings with GPU/CPU support and vector similarity search."""
    
    def __init__(self, 
                 model_name: str = 'all-MiniLM-L6-v2',
                 cache_dir: str = None,
                 use_gpu: bool = None):
        """
        Initialize embedding manager.
        
        Args:
            model_name: SentenceTransformer model name
            cache_dir: Directory to cache embeddings and index
            use_gpu: Force GPU usage (None = auto-detect)
        """
        self.model_name = model_name
        self.cache_dir = cache_dir or os.path.expanduser("~/.mr_kg_cache")
        
        # Auto-detect GPU availability
        if use_gpu is None:
            import torch
            self.use_gpu = torch.cuda.is_available()
        else:
            self.use_gpu = use_gpu
            
        # Initialize model
        device = 'cuda' if self.use_gpu else 'cpu'
        logger.info(f"Initializing embedding model on {device}")
        
        self.model = SentenceTransformer(model_name, device=device)
        self.embedding_dim = self.model.get_sentence_embedding_dimension()
        
        # Initialize vector index
        self.index = None
        self.entity_mapping = {}  # Maps index positions to entity names
        self.entity_embeddings = {}  # Cache embeddings
        
        # Ensure cache directory exists
        os.makedirs(self.cache_dir, exist_ok=True)
        
        # Load existing index if available
        self._load_index()
        
        logger.info(f"EmbeddingManager initialized with {model_name} on {device}")
    
    def _get_index_path(self) -> str:
        """Get path for FAISS index file."""
        return os.path.join(self.cache_dir, f"faiss_index_{self.model_name.replace('/', '_')}.index")
    
    def _get_mapping_path(self) -> str:
        """Get path for entity mapping file."""
        return os.path.join(self.cache_dir, f"entity_mapping_{self.model_name.replace('/', '_')}.pkl")
    
    def _load_index(self):
        """Load existing FAISS index and entity mapping."""
        index_path = self._get_index_path()
        mapping_path = self._get_mapping_path()
        
        if FAISS_AVAILABLE and os.path.exists(index_path) and os.path.exists(mapping_path):
            try:
                self.index = faiss.read_index(index_path)
                with open(mapping_path, 'rb') as f:
                    self.entity_mapping = pickle.load(f)
                logger.info(f"Loaded existing index with {len(self.entity_mapping)} entities")
            except Exception as e:
                logger.warning(f"Failed to load existing index: {e}")
                self._initialize_index()
        else:
            self._initialize_index()
    
    def _initialize_index(self):
        """Initialize new FAISS index."""
        if FAISS_AVAILABLE:
            # Use GPU index if available
            if self.use_gpu and hasattr(faiss, 'StandardGpuResources'):
                try:
                    res = faiss.StandardGpuResources()
                    self.index = faiss.GpuIndexFlatIP(res, self.embedding_dim)
                    logger.info("Initialized GPU FAISS index")
                except Exception as e:
                    logger.warning(f"GPU FAISS failed, falling back to CPU: {e}")
                    self.index = faiss.IndexFlatIP(self.embedding_dim)
            else:
                self.index = faiss.IndexFlatIP(self.embedding_dim)  # Inner product for cosine similarity
                logger.info("Initialized CPU FAISS index")
        else:
            logger.info("Using sklearn fallback for vector search")
        
        self.entity_mapping = {}
    
    def _save_index(self):
        """Save FAISS index and entity mapping to disk."""
        if FAISS_AVAILABLE and self.index is not None:
            try:
                # Convert GPU index to CPU for saving
                if hasattr(self.index, 'index'):
                    # This is a GPU index, extract CPU version
                    cpu_index = faiss.index_gpu_to_cpu(self.index)
                else:
                    cpu_index = self.index
                
                faiss.write_index(cpu_index, self._get_index_path())
                
                with open(self._get_mapping_path(), 'wb') as f:
                    pickle.dump(self.entity_mapping, f)
                
                logger.info(f"Saved index with {len(self.entity_mapping)} entities")
            except Exception as e:
                logger.error(f"Failed to save index: {e}")
    
    def generate_embedding(self, text: str) -> np.ndarray:
        """Generate embedding for text."""
        if not text or not text.strip():
            return np.zeros(self.embedding_dim)
        
        # Normalize embeddings for cosine similarity
        embedding = self.model.encode([text.strip()], normalize_embeddings=True)[0]
        return embedding.astype(np.float32)
    
    def add_entity_embedding(self, entity_name: str, text_description: str) -> bool:
        """Add entity embedding to the index."""
        try:
            embedding = self.generate_embedding(text_description)
            
            # Store in cache
            self.entity_embeddings[entity_name] = {
                'embedding': embedding,
                'text': text_description
            }
            
            if FAISS_AVAILABLE and self.index is not None:
                # Add to FAISS index
                current_size = len(self.entity_mapping)
                self.entity_mapping[current_size] = entity_name
                
                # FAISS expects 2D array
                self.index.add(embedding.reshape(1, -1))
            
            return True
            
        except Exception as e:
            logger.error(f"Failed to add entity embedding for {entity_name}: {e}")
            return False
    
    def find_similar(self, 
                    query: str, 
                    k: int = 10, 
                    threshold: float = 0.0) -> List[Dict[str, Union[str, float]]]:
        """Find entities similar to query text."""
        if not query or not query.strip():
            return []
        
        query_embedding = self.generate_embedding(query)
        
        if FAISS_AVAILABLE and self.index is not None and len(self.entity_mapping) > 0:
            return self._faiss_search(query_embedding, k, threshold)
        else:
            return self._sklearn_search(query_embedding, k, threshold)
    
    def _faiss_search(self, 
                     query_embedding: np.ndarray, 
                     k: int, 
                     threshold: float) -> List[Dict[str, Union[str, float]]]:
        """Search using FAISS index."""
        try:
            # Search for similar vectors
            scores, indices = self.index.search(query_embedding.reshape(1, -1), 
                                              min(k, len(self.entity_mapping)))
            
            results = []
            for score, idx in zip(scores[0], indices[0]):
                if idx != -1 and score >= threshold:  # -1 indicates no match
                    entity_name = self.entity_mapping[idx]
                    results.append({
                        'entity': entity_name,
                        'score': float(score),
                        'text': self.entity_embeddings.get(entity_name, {}).get('text', '')
                    })
            
            return sorted(results, key=lambda x: x['score'], reverse=True)
            
        except Exception as e:
            logger.error(f"FAISS search failed: {e}")
            return self._sklearn_search(query_embedding, k, threshold)
    
    def _sklearn_search(self, 
                       query_embedding: np.ndarray, 
                       k: int, 
                       threshold: float) -> List[Dict[str, Union[str, float]]]:
        """Fallback search using sklearn cosine similarity."""
        if not self.entity_embeddings:
            return []
        
        try:
            # Get all embeddings
            entities = list(self.entity_embeddings.keys())
            embeddings = np.array([self.entity_embeddings[entity]['embedding'] 
                                 for entity in entities])
            
            # Calculate cosine similarities
            similarities = cosine_similarity([query_embedding], embeddings)[0]
            
            # Get top k results above threshold
            results = []
            for i, (entity, score) in enumerate(zip(entities, similarities)):
                if score >= threshold:
                    results.append({
                        'entity': entity,
                        'score': float(score),
                        'text': self.entity_embeddings[entity]['text']
                    })
            
            # Sort by score and return top k
            results.sort(key=lambda x: x['score'], reverse=True)
            return results[:k]
            
        except Exception as e:
            logger.error(f"Sklearn search failed: {e}")
            return []
    
    def get_embedding(self, entity_name: str) -> Optional[np.ndarray]:
        """Get cached embedding for entity."""
        if entity_name in self.entity_embeddings:
            return self.entity_embeddings[entity_name]['embedding']
        return None
    
    def remove_entity(self, entity_name: str) -> bool:
        """Remove entity from embeddings (note: FAISS doesn't support removal)."""
        if entity_name in self.entity_embeddings:
            del self.entity_embeddings[entity_name]
            # For FAISS, we'd need to rebuild the index
            # This is a limitation of FAISS - consider using alternatives for frequent deletions
            logger.warning(f"Removed {entity_name} from cache. FAISS index rebuild required for full removal.")
            return True
        return False
    
    def get_stats(self) -> Dict[str, Union[int, str, bool]]:
        """Get embedding manager statistics."""
        return {
            'model_name': self.model_name,
            'embedding_dim': self.embedding_dim,
            'use_gpu': self.use_gpu,
            'faiss_available': FAISS_AVAILABLE,
            'total_entities': len(self.entity_embeddings),
            'index_size': len(self.entity_mapping) if self.entity_mapping else 0,
            'cache_dir': self.cache_dir
        }
    
    def save(self):
        """Save current state to disk."""
        self._save_index()
    
    def __del__(self):
        """Cleanup and save on destruction."""
        try:
            self._save_index()
        except:
            pass  # Ignore errors during cleanup
