"""Standard entity types and contact management for MindRoot Knowledge Graph."""

import json
import os
from typing import Dict, List, Any, Optional
from datetime import datetime

# Standard entity types that are always available
STANDARD_ENTITY_TYPES = {
    "Person": {
        "description": "Individual people, contacts, authors, etc.",
        "properties": ["email", "phone", "organization", "role", "location"],
        "always_include": True
    },
    "Organization": {
        "description": "Companies, institutions, groups",
        "properties": ["website", "industry", "location", "size"],
        "always_include": True
    },
    "File": {
        "description": "Documents, files, attachments",
        "properties": ["path", "size", "modified_date", "file_type", "source"],
        "always_include": True
    },
    "Document": {
        "description": "Specific documents like contracts, reports, etc.",
        "properties": ["document_type", "date_created", "author", "status"],
        "always_include": True
    },
    "Project": {
        "description": "Work projects, initiatives, tasks",
        "properties": ["status", "start_date", "end_date", "priority"],
        "always_include": True
    },
    "Location": {
        "description": "Places, addresses, geographical locations",
        "properties": ["address", "city", "country", "coordinates"],
        "always_include": True
    },
    "Event": {
        "description": "Meetings, conferences, deadlines, activities",
        "properties": ["date", "time", "location", "attendees", "type"],
        "always_include": True
    },
    "Concept": {
        "description": "Ideas, topics, subjects, technologies",
        "properties": ["category", "complexity", "related_fields"],
        "always_include": False
    },
    "TextChunk": {
        "description": "Indexed text segments from documents",
        "properties": ["source_file", "chunk_index", "word_count"],
        "always_include": False
    }
}

# File operation types for tracking
FILE_OPERATIONS = {
    "sent": "File was sent to someone",
    "received": "File was received from someone", 
    "downloaded": "File was downloaded from a source",
    "uploaded": "File was uploaded to a destination",
    "created": "File was created",
    "modified": "File was modified",
    "deleted": "File was deleted",
    "shared": "File was shared with others",
    "accessed": "File was accessed/opened"
}

class ContactManager:
    """Manages contacts (Person entities) in the knowledge graph."""
    
    def __init__(self, storage_path: str):
        self.storage_path = storage_path
        self.contacts_file = os.path.join(storage_path, 'contacts.json')
        os.makedirs(storage_path, exist_ok=True)
        self.contacts = self._load_contacts()
    
    def _load_contacts(self) -> Dict[str, Any]:
        """Load contacts from storage."""
        if os.path.exists(self.contacts_file):
            try:
                with open(self.contacts_file, 'r') as f:
                    return json.load(f)
            except Exception:
                return {}
        return {}
    
    def _save_contacts(self):
        """Save contacts to storage."""
        try:
            with open(self.contacts_file, 'w') as f:
                json.dump(self.contacts, f, indent=2, default=str)
        except Exception as e:
            print(f"Error saving contacts: {e}")
    
    def add_contact(self, name: str, properties: Dict[str, Any] = None) -> bool:
        """Add or update a contact."""
        properties = properties or {}
        
        contact_data = {
            'name': name,
            'type': 'Person',
            'added_at': datetime.now().isoformat(),
            'last_updated': datetime.now().isoformat(),
            **properties
        }
        
        self.contacts[name] = contact_data
        self._save_contacts()
        return True
    
    def get_contact(self, name: str) -> Optional[Dict[str, Any]]:
        """Get contact information."""
        return self.contacts.get(name)
    
    def list_contacts(self) -> List[Dict[str, Any]]:
        """List all contacts."""
        return list(self.contacts.values())
    
    def search_contacts(self, query: str) -> List[Dict[str, Any]]:
        """Search contacts by name or properties."""
        query_lower = query.lower()
        results = []
        
        for contact in self.contacts.values():
            # Search in name
            if query_lower in contact['name'].lower():
                results.append(contact)
                continue
            
            # Search in properties
            for key, value in contact.items():
                if isinstance(value, str) and query_lower in value.lower():
                    results.append(contact)
                    break
        
        return results
    
    def get_contact_names(self) -> List[str]:
        """Get list of all contact names."""
        return list(self.contacts.keys())

def get_entity_types_prompt() -> str:
    """Generate prompt text with standard entity types."""
    prompt_parts = [
        "=== ENTITY TYPES TO EXTRACT ===",
        "",
        "When analyzing text, you MUST categorize entities into one of these types:",
        ""
    ]
    
    # First list all entity types clearly
    for entity_type, info in STANDARD_ENTITY_TYPES.items():
        prompt_parts.append(f"• {entity_type}: {info['description']}")
        if info.get('properties'):
            prompt_parts.append(f"  Properties: {', '.join(info['properties'])}")
        prompt_parts.append("")  # Add spacing between types
    
    prompt_parts.extend([
        "=== EXTRACTION GUIDELINES ===",
        "",
        "For file-related entities, always include:",
        "- File name and path",
        "- File operations (sent, received, downloaded, etc.)",
        "- Associated people and organizations",
        "- Timestamps when available",
        "",
        "Available file operation types:",
    ])
    
    # Add file operations list
    for op_type, description in FILE_OPERATIONS.items():
        prompt_parts.append(f"• {op_type}: {description}")
    
    prompt_parts.extend([
        "",
        "Focus on extracting:",
        "1. People and their relationships to files/documents",
        "2. Organizations and their document relationships", 
        "3. File operations and temporal information",
        "4. Document types and their metadata"
    ])
    
    return "\n".join(prompt_parts)

def get_file_operation_types() -> Dict[str, str]:
    """Get available file operation types."""
    return FILE_OPERATIONS.copy()