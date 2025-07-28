#!/usr/bin/env python3
"""Index your own files and directories into the knowledge graph."""

import sys
import os
import argparse
from pathlib import Path

# Add the current directory to the path
sys.path.insert(0, os.path.dirname(__file__))

from file_commands import kg_index_directory
from graph_commands import kg_get_stats
import asyncio

async def index_my_files(directory_path, recursive=True):
    """Index your own files into the knowledge graph."""
    
    print(f"🔍 Indexing directory: {directory_path}")
    print("=" * 50)
    
    # Check if directory exists
    if not os.path.exists(directory_path):
        print(f"❌ Directory not found: {directory_path}")
        return False
    
    # Index the directory
    result = await kg_index_directory(
        path=directory_path,
        recursive=recursive,
        file_extensions=None  # Process all file types
    )
    
    if result.get('success'):
        print(f"✅ Indexing completed successfully!")
        print(f"📊 Files processed: {result.get('files_processed', 0)}")
        print(f"📊 Files skipped: {result.get('files_skipped', 0)}")
        print(f"📊 Total errors: {result.get('total_errors', 0)}")
        
        if result.get('errors'):
            print("\n⚠️  Errors encountered:")
            for error in result['errors'][:5]:  # Show first 5 errors
                print(f"   - {error}")
            if len(result['errors']) > 5:
                print(f"   ... and {len(result['errors']) - 5} more errors")
        
        # Show graph statistics
        stats_result = await kg_get_stats()
        if stats_result.get('success'):
            stats = stats_result.get('graph', {})
            print(f"\n📈 Knowledge Graph Statistics:")
            print(f"   Entities: {stats.get('num_entities', 0)}")
            print(f"   Relationships: {stats.get('num_relationships', 0)}")
        
        return True
    else:
        print(f"❌ Indexing failed: {result.get('error')}")
        return False

def main():
    """Main function."""
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
    success = asyncio.run(index_my_files(directory_path, recursive=not args.no_recursive))
    
    if success:
        print(f"\n✅ Your files have been indexed!")
        print(f"💡 Next steps:")
        print(f"   1. Export the graph: python export_graph.py")
        print(f"   2. Visualize it: python vis.py kg_export.json -f png --open")
        print(f"   3. Query it: Use the web interface or YAML queries")
    else:
        print(f"\n❌ Indexing failed. Please check the directory path and permissions.")
    
    return 0 if success else 1

if __name__ == "__main__":
    exit(main()) 