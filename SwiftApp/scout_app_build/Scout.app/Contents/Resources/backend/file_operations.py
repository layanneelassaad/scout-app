"""File operations module for the Knowledge Graph plugin."""

import os
import hashlib
import logging
from datetime import datetime
from typing import Dict, Any, Optional
from pathlib import Path

# Use a try-except block for optional dependencies
try:
    from unstructured.partition.auto import partition
    UNSTRUCTURED_AVAILABLE = True
except ImportError:
    UNSTRUCTURED_AVAILABLE = False
    logging.warning("`unstructured` library not found. File parsing will be limited to plain text.")

# Import email parser
try:
    from .email_parser import parse_eml_file
    EMAIL_PARSER_AVAILABLE = True
except ImportError:
    EMAIL_PARSER_AVAILABLE = False
    logging.warning("Email parser not available. .eml files will be processed as plain text.")

logger = logging.getLogger(__name__)

class FileOperations:
    """Handles file reading, hashing, and metadata extraction."""
    
    @staticmethod
    def calculate_file_hash(file_path: str) -> str:
        """Calculate the SHA256 hash of a file's content."""
        sha256_hash = hashlib.sha256()
        try:
            with open(file_path, "rb") as f:
                for byte_block in iter(lambda: f.read(4096), b""):
                    sha256_hash.update(byte_block)
            return sha256_hash.hexdigest()
        except IOError:
            return ""
    
    @staticmethod
    def read_file_content(file_path: str, max_size: Optional[int] = None) -> str:
        """Read file content using the unstructured library if available.
        
        Args:
            file_path: Path to the file to read
            max_size: Maximum number of characters to read (None for no limit)
        """
        # Check if this is an .eml file and use custom parser
        if file_path.lower().endswith('.eml') and EMAIL_PARSER_AVAILABLE:
            try:
                logger.info(f"Using custom email parser for {file_path}")
                content = parse_eml_file(file_path)
                if max_size and len(content) > max_size:
                    content = content[:max_size]
                return content
            except Exception as e:
                logger.warning(f"Email parser failed on {file_path}: {e}. Falling back to unstructured.")
                # Continue to unstructured/fallback methods
        
        if UNSTRUCTURED_AVAILABLE:
            try:
                elements = partition(filename=file_path)
                content = "\n\n".join([str(el) for el in elements])
                if max_size and len(content) > max_size:
                    content = content[:max_size]
                return content
            except Exception as e:
                logger.warning(f"Unstructured failed on {file_path}: {e}. Falling back to plain text.")
        
        # Fallback to simple text reading
        try:
            with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
                if max_size:
                    return f.read(max_size)
                else:
                    return f.read()
        except Exception as read_e:
            logger.error(f"Fallback read for {file_path} also failed: {read_e}")
            return ""
    
    @staticmethod
    def extract_file_metadata(file_path: str) -> Dict[str, Any]:
        """Extract metadata from file."""
        try:
            stat = os.stat(file_path)
            path_obj = Path(file_path)
            
            return {
                'file_name': path_obj.name,
                'file_stem': path_obj.stem,
                'file_extension': path_obj.suffix,
                'file_size': stat.st_size,
                'modified_date': datetime.fromtimestamp(stat.st_mtime).isoformat(),
                'created_date': datetime.fromtimestamp(stat.st_ctime).isoformat(),
                'full_path': os.path.abspath(file_path),
                'directory': str(path_obj.parent),
                'is_hidden': path_obj.name.startswith('.')
            }
        except Exception as e:
            logger.error(f"Error extracting metadata for {file_path}: {e}")
            return {}