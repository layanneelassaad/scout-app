"""Parser for line-based entity/relationship format."""

import logging
from typing import Dict, List, Any, Optional, Tuple

logger = logging.getLogger(__name__)

class LineFormatParser:
    """Parses line-based format for entities and relationships.
    
    Format:
    E|name|type|description
    R|source|type|target
    
    Where:
    - E indicates an entity line
    - R indicates a relationship line
    - | is the delimiter
    """
    
    @staticmethod
    def parse(content: str) -> Dict[str, Any]:
        """Parse line-based format into standard JSON structure.
        
        Args:
            content: Line-based format string
            
        Returns:
            Dictionary with 'entities' and 'relationships' keys
        """
        entities = []
        relationships = []
        
        lines = content.strip().split('\n')
        
        for line_num, line in enumerate(lines, 1):
            line = line.strip()
            if not line:
                continue
                
            try:
                parts = line.split('|')
                if len(parts) < 1:
                    logger.warning(f"Line {line_num}: Empty line, skipping")
                    continue
                    
                line_type = parts[0].upper()
                
                if line_type == 'E':
                    if len(parts) < 4:
                        logger.error(f"Line {line_num}: Entity line requires 4 parts, got {len(parts)}: {line}")
                        continue
                    
                    entity = {
                        "name": parts[1].strip(),
                        "type": parts[2].strip(),
                        "description": parts[3].strip()
                    }
                    
                    # Handle optional properties if present (5th part)
                    if len(parts) > 4 and parts[4].strip():
                        properties = LineFormatParser._parse_properties(parts[4].strip())
                        if properties:
                            entity["properties"] = properties
                    
                    entities.append(entity)
                    
                elif line_type == 'R':
                    if len(parts) < 4:
                        logger.error(f"Line {line_num}: Relationship line requires 4 parts, got {len(parts)}: {line}")
                        continue
                    
                    relationship = {
                        "source": parts[1].strip(),
                        "type": parts[2].strip(),
                        "target": parts[3].strip()
                    }
                    
                    # Handle optional properties if present (5th part)
                    if len(parts) > 4 and parts[4].strip():
                        properties = LineFormatParser._parse_properties(parts[4].strip())
                        if properties:
                            relationship["properties"] = properties
                    
                    relationships.append(relationship)
                    
                else:
                    logger.warning(f"Line {line_num}: Unknown line type '{line_type}', skipping: {line}")
                    
            except Exception as e:
                logger.error(f"Line {line_num}: Error parsing line '{line}': {e}")
                continue
        
        return {
            "entities": entities,
            "relationships": relationships
        }
    
    @staticmethod
    def _parse_properties(prop_string: str) -> Optional[Dict[str, Any]]:
        """Parse property string in format: key1=value1;key2=value2
        
        Args:
            prop_string: Property string
            
        Returns:
            Dictionary of properties or None if parsing fails
        """
        if not prop_string:
            return None
            
        properties = {}
        pairs = prop_string.split(';')
        
        for pair in pairs:
            pair = pair.strip()
            if '=' not in pair:
                continue
                
            key, value = pair.split('=', 1)
            key = key.strip()
            value = value.strip()
            
            if key:
                properties[key] = value
        
        return properties if properties else None
    
    @staticmethod
    def format_example() -> str:
        """Return an example of the line-based format."""
        return """E|John Smith|Person|Project manager at tech company
E|Acme Corp|Organization|Software development company
E|Project Alpha|Project|AI research project
R|File:report.pdf|mentions|John Smith
R|John Smith|works_at|Acme Corp
R|John Smith|works_on|Project Alpha
R|Project Alpha|owned_by|Acme Corp"""
    
    @staticmethod
    def format_instructions() -> str:
        """Return instructions for the line-based format."""
        return """OUTPUT FORMAT: Use line-based format with pipe delimiter (|)

Each line must be one of:
- Entity: E|name|type|description
- Relationship: R|source|type|target

Rules:
- One item per line
- Use pipe character (|) as delimiter
- No spaces around pipes
- Entity types must be from the allowed list
- Relationship types should be descriptive verbs/phrases

Optional 5th field for properties (key=value;key2=value2):
- Entity: E|name|type|description|email=john@example.com;role=manager
- Relationship: R|source|type|target|since=2020;strength=0.8

Example:
E|John Smith|Person|Senior engineer
E|TechCorp|Organization|Technology company
R|John Smith|works_at|TechCorp
R|File:memo.txt|mentions|John Smith"""