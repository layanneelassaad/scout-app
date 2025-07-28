"""Content processing module for the Knowledge Graph plugin."""

import logging
from typing import List

# Use a try-except block for optional dependencies
try:
    from langchain.text_splitter import RecursiveCharacterTextSplitter
    LANGCHAIN_AVAILABLE = True
except ImportError:
    LANGCHAIN_AVAILABLE = False
    logging.warning("`langchain` library not found. Text chunking will use a basic splitter.")

logger = logging.getLogger(__name__)

class ContentProcessor:
    """Handles text chunking and content processing operations."""
    
    @staticmethod
    def chunk_text(text: str, chunk_size: int = 2000, overlap: int = 200) -> List[str]:
        """Split text into manageable chunks.
        
        Args:
            text: Text to chunk
            chunk_size: Size of each chunk (default increased to 2000)
            overlap: Overlap between chunks (default increased to 200)
        """
        if not text:
            return []
        
        if LANGCHAIN_AVAILABLE:
            text_splitter = RecursiveCharacterTextSplitter(
                chunk_size=chunk_size,
                chunk_overlap=overlap,
                length_function=len,
            )
            return text_splitter.split_text(text)
        else:
            # Basic fallback splitter
            return [text[i:i+chunk_size] for i in range(0, len(text), chunk_size - overlap)]
    
    @staticmethod
    def prepare_analysis_content(content: str, max_chars: int = 40000) -> str:
        """Prepare content for analysis by limiting size and cleaning.
        
        Args:
            content: Full file content
            max_chars: Maximum characters to use for analysis (default 40KB)
        """
        if not content:
            return ""
        
        # Take first 40KB of content for analysis
        if len(content) > max_chars:
            content = content[:max_chars]
            # Try to end at a reasonable boundary (sentence, paragraph)
            last_period = content.rfind('.')
            last_newline = content.rfind('\n')
            
            # Use the later of the two boundaries if they're within 200 chars of the end
            boundary = max(last_period, last_newline)
            if boundary > max_chars - 200:
                content = content[:boundary + 1]
        
        return content.strip()
