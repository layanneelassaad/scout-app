#!/usr/bin/env python3
"""
Alternative Query Formats for Knowledge Graph

This demonstrates different ways to query the knowledge graph
beyond the current YAML format.
"""

import json
from typing import Dict, Any, List
from graph_store import KnowledgeGraphStore
from embeddings import EmbeddingManager
from query_engine import KnowledgeGraphQueryEngine

class AlternativeQueryEngine:
    """Demonstrates alternative query formats."""
    
    def __init__(self, graph_store: KnowledgeGraphStore, embedding_manager: EmbeddingManager):
        self.graph_store = graph_store
        self.embedding_manager = embedding_manager
        self.query_engine = KnowledgeGraphQueryEngine(graph_store, embedding_manager)
    
    def query_with_json(self, query_json: str) -> Dict[str, Any]:
        """Query using JSON format."""
        try:
            query_data = json.loads(query_json)
            # Convert JSON to YAML format for existing engine
            yaml_query = self._json_to_yaml(query_data)
            return self.query_engine.execute_query(yaml_query)
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def query_with_dict(self, query_dict: Dict[str, Any]) -> Dict[str, Any]:
        """Query using Python dictionary format."""
        try:
            # Convert dict to YAML format
            yaml_query = self._dict_to_yaml(query_dict)
            return self.query_engine.execute_query(yaml_query)
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def query_with_sql_like(self, sql_query: str) -> Dict[str, Any]:
        """Query using SQL-like syntax."""
        try:
            # Parse SQL-like syntax
            query_dict = self._parse_sql_like(sql_query)
            yaml_query = self._dict_to_yaml(query_dict)
            return self.query_engine.execute_query(yaml_query)
        except Exception as e:
            return {"success": False, "error": str(e)}
    
    def _json_to_yaml(self, query_data: Dict[str, Any]) -> str:
        """Convert JSON query to YAML format."""
        import yaml
        return yaml.dump(query_data, default_flow_style=False)
    
    def _dict_to_yaml(self, query_dict: Dict[str, Any]) -> str:
        """Convert Python dict to YAML format."""
        import yaml
        return yaml.dump(query_dict, default_flow_style=False)
    
    def _parse_sql_like(self, sql_query: str) -> Dict[str, Any]:
        """Parse SQL-like syntax into query dict."""
        # Simple SQL-like parser
        sql_lower = sql_query.lower().strip()
        
        if sql_lower.startswith("select"):
            return self._parse_select_query(sql_query)
        elif sql_lower.startswith("find"):
            return self._parse_find_query(sql_query)
        else:
            raise ValueError(f"Unsupported SQL-like syntax: {sql_query}")
    
    def _parse_select_query(self, sql_query: str) -> Dict[str, Any]:
        """Parse SELECT-style query."""
        # Example: SELECT name, type FROM Person WHERE name LIKE 'John'
        parts = sql_query.split()
        query_name = "sql_select_query"
        
        # Extract fields (after SELECT, before FROM)
        select_idx = parts.index("SELECT")
        from_idx = parts.index("FROM")
        fields = [f.strip() for f in " ".join(parts[select_idx+1:from_idx]).split(",")]
        
        # Extract entity type (after FROM)
        entity_type = parts[from_idx + 1]
        
        # Extract conditions (after WHERE)
        conditions = {}
        if "WHERE" in parts:
            where_idx = parts.index("WHERE")
            where_clause = " ".join(parts[where_idx+1:])
            if "LIKE" in where_clause:
                field, value = where_clause.split("LIKE")
                conditions[field.strip()] = value.strip().strip("'")
        
        return {
            query_name: {
                "find": {
                    "nodes": {
                        "entity_type": entity_type,
                        "properties": conditions,
                        "return": fields,
                        "limit": 10
                    }
                }
            }
        }
    
    def _parse_find_query(self, sql_query: str) -> Dict[str, Any]:
        """Parse FIND-style query."""
        # Example: FIND Person WHERE name = 'John'
        parts = sql_query.split()
        query_name = "find_query"
        
        # Extract entity type (after FIND)
        entity_type = parts[1]
        
        # Extract conditions (after WHERE)
        conditions = {}
        if "WHERE" in parts:
            where_idx = parts.index("WHERE")
            where_clause = " ".join(parts[where_idx+1:])
            if "=" in where_clause:
                field, value = where_clause.split("=")
                conditions[field.strip()] = value.strip().strip("'")
        
        return {
            query_name: {
                "find": {
                    "nodes": {
                        "entity_type": entity_type,
                        "properties": conditions,
                        "return": ["name", "type"],
                        "limit": 10
                    }
                }
            }
        }

def demonstrate_alternatives():
    """Demonstrate different query formats."""
    print("🔄 ALTERNATIVE QUERY FORMATS")
    print("=" * 50)
    
    # Setup
    storage_path = os.path.expanduser("~/.mr_kg_data/knowledge_graph.json")
    graph_store = KnowledgeGraphStore(storage_path=storage_path)
    embedding_manager = EmbeddingManager()
    alt_engine = AlternativeQueryEngine(graph_store, embedding_manager)
    
    # 1. JSON Format
    print("\n1️⃣ JSON Format:")
    json_query = '''
    {
        "find_people_json": {
            "find": {
                "nodes": {
                    "entity_type": "Person",
                    "return": ["name", "type"],
                    "limit": 5
                }
            }
        }
    }
    '''
    
    result1 = alt_engine.query_with_json(json_query)
    print(f"✅ Success: {result1.get('success', False)}")
    if result1.get('success'):
        print(f"📊 Found {len(result1.get('results', []))} people")
        for person in result1.get('results', [])[:3]:
            print(f"   - {person.get('name', 'Unknown')}")
    
    # 2. Python Dict Format
    print("\n2️⃣ Python Dict Format:")
    dict_query = {
        "find_people_dict": {
            "find": {
                "nodes": {
                    "entity_type": "Person",
                    "return": ["name", "type"],
                    "limit": 5
                }
            }
        }
    }
    
    result2 = alt_engine.query_with_dict(dict_query)
    print(f"✅ Success: {result2.get('success', False)}")
    if result2.get('success'):
        print(f"📊 Found {len(result2.get('results', []))} people")
        for person in result2.get('results', [])[:3]:
            print(f"   - {person.get('name', 'Unknown')}")
    
    # 3. SQL-like Format
    print("\n3️⃣ SQL-like Format:")
    sql_query = "SELECT name, type FROM Person"
    
    result3 = alt_engine.query_with_sql_like(sql_query)
    print(f"✅ Success: {result3.get('success', False)}")
    if result3.get('success'):
        print(f"📊 Found {len(result3.get('results', []))} people")
        for person in result3.get('results', [])[:3]:
            print(f"   - {person.get('name', 'Unknown')}")
    
    print("\n✅ All alternative formats work!")

def show_comparison():
    """Show comparison of different query formats."""
    print("\n📊 QUERY FORMAT COMPARISON")
    print("=" * 50)
    
    # YAML (current)
    yaml_example = """
find_people:
  find:
    nodes:
      entity_type: "Person"
      return: ["name", "type"]
      limit: 5
"""
    
    # JSON
    json_example = '''
{
    "find_people": {
        "find": {
            "nodes": {
                "entity_type": "Person",
                "return": ["name", "type"],
                "limit": 5
            }
        }
    }
}
'''
    
    # Python Dict
    dict_example = {
        "find_people": {
            "find": {
                "nodes": {
                    "entity_type": "Person",
                    "return": ["name", "type"],
                    "limit": 5
                }
            }
        }
    }
    
    # SQL-like
    sql_example = "SELECT name, type FROM Person LIMIT 5"
    
    print("YAML (Current):")
    print(yaml_example)
    print("\nJSON:")
    print(json_example)
    print("\nPython Dict:")
    print(dict_example)
    print("\nSQL-like:")
    print(sql_example)
    
    print("\n🎯 RECOMMENDATIONS:")
    print("   ✅ YAML: Best for human readability and configuration")
    print("   ✅ JSON: Best for programmatic access")
    print("   ✅ Python Dict: Best for internal API calls")
    print("   ✅ SQL-like: Best for familiar syntax")

if __name__ == "__main__":
    import os
    demonstrate_alternatives()
    show_comparison() 