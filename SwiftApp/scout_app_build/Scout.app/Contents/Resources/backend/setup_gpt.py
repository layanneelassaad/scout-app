#!/usr/bin/env python3
"""
Setup GPT Service for Knowledge Graph

This script sets up the GPT API service for entity extraction
using your existing knowledge graph code.
"""

import os
import sys
import asyncio
import aiohttp
import openai
from entity_analyzer import service_manager

# Load environment variables from .env file
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("⚠️  python-dotenv not installed. Install with: pip install python-dotenv")
    print("   Or set OPENAI_API_KEY environment variable manually")

# Get API key from environment
openai.api_key = os.getenv("OPENAI_API_KEY")

class GPTService:
    """Simple GPT API service for entity extraction."""
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.base_url = "https://api.openai.com/v1"
        self.model = "gpt-4o-mini"
    
    async def prompt(self, model_name: str, prompt_input: str) -> str:
        """Send prompt to GPT API and return response."""
        try:
            # Use the provided model name or default to GPT model
            model = model_name if not model_name.startswith("models/gemini") else self.model
            
            headers = {
                "Authorization": f"Bearer {self.api_key}",
                "Content-Type": "application/json"
            }
            
            data = {
                "model": model,
                "messages": [
                    {
                        "role": "system",
                        "content": "You are an expert at extracting entities and relationships from documents for knowledge graph construction. Follow the instructions carefully and return the response in the exact format specified."
                    },
                    {
                        "role": "user",
                        "content": prompt_input
                    }
                ],
                "temperature": 0.1,
                "max_tokens": 2000
            }
            
            async with aiohttp.ClientSession() as session:
                async with session.post(
                    f"{self.base_url}/chat/completions",
                    headers=headers,
                    json=data
                ) as response:
                    if response.status == 200:
                        result = await response.json()
                        return result["choices"][0]["message"]["content"]
                    else:
                        error_text = await response.text()
                        print(f"GPT API error: {response.status} - {error_text}")
                        return ""
                        
        except Exception as e:
            print(f"Error calling GPT API: {e}")
            return ""

def setup_gpt_service():
    """Setup GPT service with API key."""
    try:
        # Get API key from environment
        api_key = os.getenv("OPENAI_API_KEY")
        if not api_key:
            raise ValueError("OPENAI_API_KEY not found in environment variables")
        
        # Create GPT service
        gpt_service = GPTService(api_key)
        
        # Register the prompt function
        service_manager.register_function(
            name="prompt",
            module_name="gpt_service",
            func=gpt_service.prompt,
            signature="async def prompt(model_name: str, prompt_input: str) -> str",
            docstring="GPT API service for entity extraction",
            flags=[]
        )
        
        print("✅ GPT service registered successfully!")
        return True
        
    except Exception as e:
        print(f"❌ Failed to setup GPT service: {e}")
        return False

def test_with_files(file_paths):
    """Test the GPT service with specified files."""
    print("🧠 Testing GPT Service with Your Files")
    print("=" * 60)
    
    # Import your existing components
    from graph_store import KnowledgeGraphStore
    from file_indexer import FileIndexer
    from embeddings import EmbeddingManager
    
    # Initialize components (same as your simple_index.py)
    storage_path = os.path.expanduser("~/.mr_kg_data/knowledge_graph.json")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    file_indexer = FileIndexer(graph_store, embedding_manager)
    
    print(f"📁 Testing with {len(file_paths)} files:")
    for file_path in file_paths:
        print(f"  - {file_path}")
    
    print("\n🚀 Starting indexing with GPT entity extraction...")
    
    async def run_test():
        for file_path in file_paths:
            if os.path.exists(file_path):
                print(f"\n📄 Processing: {file_path}")
                result = await file_indexer.index_file(file_path)
                if result.get('success'):
                    print(f"  ✅ Success: {result}")
                else:
                    print(f"  ❌ Failed: {result}")
            else:
                print(f"  ❌ File not found: {file_path}")
    
    # Run the test
    asyncio.run(run_test())
    
    # Show results
    print(f"\n📊 Final Knowledge Graph Statistics:")
    stats = graph_store.get_statistics()
    print(f"   Entities: {stats.get('num_entities', 0)}")
    print(f"   Relationships: {stats.get('num_relationships', 0)}")

def print_usage():
    """Print usage instructions."""
    print("Usage:")
    print("  python setup_gpt.py <file1> <file2> <file3> ...")
    print("  python setup_gpt.py tests/test_docs/*.txt")
    print("  python setup_gpt.py path/to/your/documents/")
    print("")
    print("Examples:")
    print("  python setup_gpt.py tests/test_docs/agreement_042.txt")
    print("  python setup_gpt.py tests/test_docs/*.txt")
    print("  python setup_gpt.py ~/Documents/*.pdf")

if __name__ == "__main__":
    # Check if files were provided
    if len(sys.argv) < 2:
        print("❌ No files specified!")
        print_usage()
        sys.exit(1)
    
    # Get file paths from command line arguments
    file_paths = sys.argv[1:]
    
    # Validate files exist
    valid_files = []
    for file_path in file_paths:
        if os.path.exists(file_path):
            valid_files.append(file_path)
        else:
            print(f"⚠️  File not found: {file_path}")
    
    if not valid_files:
        print("❌ No valid files found!")
        sys.exit(1)
    
    # Setup GPT service
    if setup_gpt_service():
        # Test with your specified files
        test_with_files(valid_files)
    else:
        print("❌ Failed to setup GPT service. Please check your API key.")
        sys.exit(1) 