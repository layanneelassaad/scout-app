#!/usr/bin/env python3
import sys, os, asyncio
from kg.graph_store   import KnowledgeGraphStore
from kg.embeddings    import EmbeddingManager
from kg.file_indexer  import FileIndexer

def main():
    if len(sys.argv) < 2:
        print("Usage: python index_docs.py <file1> <file2> …")
        sys.exit(1)

    files = sys.argv[1:]
    storage_dir = os.path.expanduser("~/.mr_kg_data")
    gs = KnowledgeGraphStore(storage_path=storage_dir)
    em = EmbeddingManager(cache_dir=os.path.join(storage_dir, "embeddings"))
    indexer = FileIndexer(gs, em)

    async def run():
        for path in files:
            print(f"\n📥 Indexing {path} …")
            res = await indexer.index_file(path)
            print("→ Result:", res)

    asyncio.run(run())

if __name__ == "__main__":
    main()
