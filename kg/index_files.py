#!/usr/bin/env python3
"""
Simple script to index files for the Scout knowledge graph.
"""

import asyncio
import sys
import os
from pathlib import Path

# Add the current directory to Python path
sys.path.insert(0, os.path.dirname(__file__))

# Fix the import issue by using relative imports
import file_commands

async def main():
    if len(sys.argv) < 2:
        print("Usage: python index_files.py <directory_path>")
        print("\nExamples:")
        print("  python index_files.py /Users/layanneelassaad/Documents")
        print("  python index_files.py /Users/layanneelassaad/Desktop")
        print("  python index_files.py /Users/layanneelassaad/Desktop/scout-app")
        return
    
    directory_path = sys.argv[1]
    
    if not os.path.exists(directory_path):
        print(f"Error: Directory '{directory_path}' does not exist")
        return
    
    if not os.path.isdir(directory_path):
        print(f"Error: '{directory_path}' is not a directory")
        return
    
    print(f"Indexing directory: {directory_path}")
    print("This will index all text files in the directory and subdirectories...")
    print("Supported file types: .txt, .md, .py, .js, .html, .css, .json, .xml, .csv, .rst, .tex, .eml")
    print()
    
    result = await file_commands.kg_index_directory(
        path=directory_path,
        recursive=True,
        file_extensions=None  # Use default extensions
    )
    
    if result.get('success'):
        print("✅ Indexing completed successfully!")
        print(f"Files processed: {result.get('files_processed', 0)}")
        print(f"Files skipped: {result.get('files_skipped', 0)}")
        
        if result.get('errors'):
            print("\n⚠️  Some errors occurred:")
            for error in result['errors']:
                print(f"  - {error}")
    else:
        print("❌ Indexing failed:")
        print(f"  {result.get('error', 'Unknown error')}")

if __name__ == "__main__":
    asyncio.run(main()) 