#!/usr/bin/env python3
"""Simple script to index your own files into the knowledge graph."""

import sys
import os
import asyncio
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from graph_store import KnowledgeGraphStore
from file_indexer import FileIndexer
from embeddings import EmbeddingManager

# Files to exclude from indexing
EXCLUDED_FILES = {
    '.DS_Store',  # macOS system file
    '.DS_Store?',  # macOS system file
    'Thumbs.db',  # Windows system file
    'desktop.ini',  # Windows system file
    '.gitignore',  # Git files
    '.gitattributes',  # Git files
    '__pycache__',  # Python cache
    '.pytest_cache',  # Python test cache
    '.coverage',  # Python coverage
    '.mypy_cache',  # Python type checker cache
    '*.pyc',  # Python compiled files
    '*.pyo',  # Python compiled files
    '*.pyd',  # Python compiled files
    '*.so',  # Compiled libraries
    '*.dll',  # Windows libraries
    '*.dylib',  # macOS libraries
    '*.exe',  # Executables
    '*.app',  # macOS applications
    '*.bundle',  # macOS bundles
}

def should_index_file(file_path: str) -> bool:
    """Check if a file should be indexed based on name and type."""
    file_name = os.path.basename(file_path)
    
    # Skip hidden files (starting with .)
    if file_name.startswith('.'):
        return False
    
    # Skip excluded files
    if file_name in EXCLUDED_FILES:
        return False
    
    # Skip system directories
    if file_name in {'node_modules', 'venv', 'env', '.venv', '.env'}:
        return False
    
    # Skip common binary and system files
    binary_extensions = {'.exe', '.dll', '.so', '.dylib', '.app', '.bundle', '.pyc', '.pyo', '.pyd'}
    file_ext = os.path.splitext(file_name)[1].lower()
    if file_ext in binary_extensions:
        return False
    
    return True

async def index_directory(directory_path, recursive=True):
    """Index a directory into the knowledge graph."""
    
    print(f"🔍 Indexing directory: {directory_path}")
    print("=" * 50)
    
    # Check if directory exists
    if not os.path.exists(directory_path):
        print(f"❌ Directory not found: {directory_path}")
        return False
    
    try:
        # Initialize components
        storage_path = os.path.expanduser("~/.mr_kg_data/knowledge_graph.json")
        graph_store = KnowledgeGraphStore(storage_path=storage_path)
        embedding_manager = EmbeddingManager()
        file_indexer = FileIndexer(graph_store, embedding_manager)
        
        # Get all files in directory
        files_to_process = []
        for root, dirs, files in os.walk(directory_path):
            if not recursive and root != directory_path:
                continue
            for file in files:
                file_path = os.path.join(root, file)
                if should_index_file(file_path):
                    files_to_process.append(file_path)
        
        print(f"📁 Found {len(files_to_process)} files to process")
        
        # Process files
        processed = 0
        skipped = 0
        errors = 0
        
        for file_path in files_to_process:
            try:
                print(f"📄 Processing: {os.path.basename(file_path)}")
                result = await file_indexer.index_file(file_path)
                if result.get('success'):
                    processed += 1
                else:
                    skipped += 1
            except Exception as e:
                print(f"❌ Error processing {file_path}: {e}")
                errors += 1
        
        print(f"\n✅ Indexing completed!")
        print(f"📊 Files processed: {processed}")
        print(f"📊 Files skipped: {skipped}")
        print(f"📊 Total errors: {errors}")
        
        # Show graph statistics
        stats = graph_store.get_statistics()
        print(f"\n📈 Knowledge Graph Statistics:")
        print(f"   Entities: {stats.get('num_entities', 0)}")
        print(f"   Relationships: {stats.get('num_relationships', 0)}")
        
        return True
            
    except Exception as e:
        print(f"❌ Error during indexing: {e}")
        import traceback
        traceback.print_exc()
        return False

def main():
    """Main function."""
    import argparse
    
    parser = argparse.ArgumentParser(description='Index your own files into the knowledge graph')
    parser.add_argument('directory', help='Directory path to index')
    parser.add_argument('--no-recursive', action='store_true', 
                       help='Don\'t index subdirectories recursively')
    
    args = parser.parse_args()
    
    # Expand user path and make absolute
    directory_path = os.path.expanduser(args.directory)
    directory_path = os.path.abspath(directory_path)
    
    print("🧠 KNOWLEDGE GRAPH FILE INDEXING")
    print("=" * 50)
    print(f"📁 Target directory: {directory_path}")
    print(f"🔄 Recursive: {not args.no_recursive}")
    print()
    
    # Run the indexing
    success = asyncio.run(index_directory(directory_path, recursive=not args.no_recursive))
    
    if success:
        print(f"\n✅ Your files have been indexed!")
        print(f"💡 Next steps:")
        print(f"   1. Export the graph: python export_graph.py")
        print(f"   2. Visualize it: python vis.py kg_export.json -f png --open")
    else:
        print(f"\n❌ Indexing failed. Please check the directory path and permissions.")
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main()) 