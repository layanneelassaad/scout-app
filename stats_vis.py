#!/usr/bin/env python3
import os
from kg.graph_store import KnowledgeGraphStore
from kg.vis import create_visualization

def main():
    # 1️⃣ Load the graph
    storage_dir = os.path.expanduser("~/.mr_kg_data")
    gs = KnowledgeGraphStore(storage_path=storage_dir)

    # 2️⃣ Print basic stats
    stats = gs.get_statistics()
    print("📊 Knowledge Graph stats:", stats)

    # 3️⃣ Build a visualization PNG
    kg_json = os.path.join(storage_dir, "knowledge_graph.json")
    output_png = "kg_graph.png"
    print(f"🔧 Generating visualization → {output_png}")
    result = create_visualization(
        kg_json_path=kg_json,
        output_path=output_png,
        format='png',
        layout='dot'
    )
    if result:
        print("✅ Visualization written to", result)
    else:
        print("❌ Visualization failed. See errors above.")

if __name__ == "__main__":
    main()
