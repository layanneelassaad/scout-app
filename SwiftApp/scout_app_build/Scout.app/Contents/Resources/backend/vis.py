#!/usr/bin/env python3
"""
Knowledge Graph Visualization Script

Creates Graphviz visualizations of knowledge graphs, filtering out TextChunk entities
and chunk-related relationships for cleaner visualization.
"""

import json
import argparse
import subprocess
import sys
from pathlib import Path


def create_visualization(kg_json_path, output_path=None, format='png', layout='dot'):
    """
    Create a knowledge graph visualization from exported JSON data.
    
    Args:
        kg_json_path: Path to the exported knowledge graph JSON file
        output_path: Output file path (auto-generated if None)
        format: Output format (png, svg, pdf, etc.)
        layout: Graphviz layout algorithm (dot, neato, fdp, sfdp, twopi, circo)
    """
    
    # Load the exported graph data
    with open(kg_json_path, 'r') as f:
        data = json.load(f)

    nodes = data['nodes']
    edges = data['links']
    
    # Filter out TextChunk entities and chunk-related relationships
    filtered_nodes = []
    for node in nodes:
        node_type = node.get('type', '')
        node_id = node.get('id', '')
        
        # Skip TextChunk entities and any node with 'chunk' in the ID
        if node_type == 'TextChunk' or 'chunk' in node_id.lower():
            continue
            
        filtered_nodes.append(node)
    
    # Get IDs of filtered nodes for edge filtering
    filtered_node_ids = {node['id'] for node in filtered_nodes}
    
    # Filter edges to exclude chunk-related relationships
    filtered_edges = []
    for edge in edges:
        edge_type = edge.get('type', '')
        source = edge.get('source', '')
        target = edge.get('target', '')
        
        # Skip chunk-related relationship types
        if 'chunk' in edge_type.lower():
            continue
            
        # Skip edges where source or target is not in our filtered nodes
        if source not in filtered_node_ids or target not in filtered_node_ids:
            continue
            
        filtered_edges.append(edge)
    
    print(f"Filtered graph: {len(filtered_nodes)} nodes, {len(filtered_edges)} edges")
    print(f"(Original: {len(nodes)} nodes, {len(edges)} edges)")

    # Create DOT content
    dot_content = f'''digraph KG {{
  rankdir=LR;
  node [shape=box, style=filled];
  overlap=false;
  splines=true;
'''

    # Define colors for different node types
    node_colors = {
        'Person': 'lightblue',
        'Organization': 'lightgreen', 
        'Concept': 'lightyellow',
        'File': 'lightcoral',
        'Document': 'lightpink',
        'Location': 'lightcyan',
        'Project': 'lavender',
        'Technology': 'lightsteelblue'
    }

    # Add nodes
    for node in filtered_nodes:
        node_type = node.get('type', 'Unknown')
        color = node_colors.get(node_type, 'white')
        
        # Clean and truncate label
        label = node['id'].replace('"', '\\"').replace('\n', ' ')
        if len(label) > 40:
            label = label[:37] + '...'
            
        # Escape node ID for DOT format
        node_id_escaped = node['id'].replace('"', '\\"')
        
        dot_content += f'  "{node_id_escaped}" [label="{label}", fillcolor={color}];\n'

    # Add edges
    for edge in filtered_edges:
        source_escaped = edge['source'].replace('"', '\\"')
        target_escaped = edge['target'].replace('"', '\\"')
        edge_type = edge['type'].replace('"', '\\"')
        
        dot_content += f'  "{source_escaped}" -> "{target_escaped}" [label="{edge_type}"];\n'

    dot_content += '}'

    # Generate output path if not provided
    if output_path is None:
        base_path = Path(kg_json_path).parent
        output_path = base_path / f'kg_visualization_{layout}.{format}'
    
    # Write DOT file
    dot_path = Path(output_path).with_suffix('.dot')
    with open(dot_path, 'w') as f:
        f.write(dot_content)
    
    print(f"DOT file created: {dot_path}")
    
    # Generate visualization using Graphviz
    cmd = ['dot', f'-T{format}', f'-K{layout}', str(dot_path), '-o', str(output_path)]
    
    try:
        subprocess.run(cmd, check=True, capture_output=True)
        print(f"Visualization created: {output_path}")
        return str(output_path)
    except subprocess.CalledProcessError as e:
        print(f"Error running Graphviz: {e}")
        print(f"Command: {' '.join(cmd)}")
        if e.stderr:
            print(f"Stderr: {e.stderr.decode()}")
        return None
    except FileNotFoundError:
        print("Error: Graphviz 'dot' command not found. Please install Graphviz.")
        print("Ubuntu/Debian: sudo apt install graphviz")
        print("macOS: brew install graphviz")
        return None


def main():
    parser = argparse.ArgumentParser(
        description='Create knowledge graph visualizations using Graphviz'
    )
    parser.add_argument(
        'kg_json', 
        help='Path to exported knowledge graph JSON file'
    )
    parser.add_argument(
        '-o', '--output', 
        help='Output file path (auto-generated if not specified)'
    )
    parser.add_argument(
        '-f', '--format', 
        default='png',
        choices=['png', 'svg', 'pdf', 'ps', 'dot'],
        help='Output format (default: png)'
    )
    parser.add_argument(
        '-l', '--layout',
        default='dot', 
        choices=['dot', 'neato', 'fdp', 'sfdp', 'twopi', 'circo'],
        help='Graphviz layout algorithm (default: dot)'
    )
    parser.add_argument(
        '--open',
        action='store_true',
        help='Open the visualization in default application'
    )
    
    args = parser.parse_args()
    
    # Check if input file exists
    if not Path(args.kg_json).exists():
        print(f"Error: Input file '{args.kg_json}' not found")
        sys.exit(1)
    
    # Create visualization
    output_path = create_visualization(
        args.kg_json, 
        args.output, 
        args.format, 
        args.layout
    )
    
    if output_path and args.open:
        try:
            # Try to open with system default application
            import webbrowser
            webbrowser.open(f'file://{Path(output_path).absolute()}')
            print(f"Opened {output_path} in default application")
        except Exception as e:
            print(f"Could not open file automatically: {e}")
            print(f"Please open manually: {output_path}")


if __name__ == '__main__':
    main()
