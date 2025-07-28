"""Comprehensive contact context management for preventing duplicate entities."""

import logging
from typing import Dict, List, Any, Optional, Set, Tuple
from .graph_store import KnowledgeGraphStore

logger = logging.getLogger(__name__)

class ContactContextManager:
    """Manages comprehensive contact context from the knowledge graph."""
    
    def __init__(self, graph_store: KnowledgeGraphStore):
        self.graph_store = graph_store
        self._contact_cache = None
        self._email_to_person_map = None
    
    def refresh_cache(self) -> None:
        """Refresh the contact cache from the graph."""
        self._contact_cache = self._load_all_contacts()
        self._email_to_person_map = self._build_email_map()
    
    def _load_all_contacts(self) -> Dict[str, Dict[str, Any]]:
        """Load all Person entities from the graph."""
        contacts = {}
        person_entities = self.graph_store.get_entities_by_type('Person')
        
        for entity_id, entity_data in person_entities:
            contacts[entity_id] = {
                'id': entity_id,
                'type': 'Person',
                'name': entity_id,  # The ID is often the name
                'email': entity_data.get('email', ''),
                'phone': entity_data.get('phone', ''),
                'organization': entity_data.get('organization', ''),
                'role': entity_data.get('role', ''),
                'description': entity_data.get('description', ''),
                'properties': entity_data
            }
        
        return contacts
    
    def _build_email_map(self) -> Dict[str, str]:
        """Build a map from email addresses to Person entity IDs."""
        email_map = {}
        
        if not self._contact_cache:
            return email_map
        
        for entity_id, contact_info in self._contact_cache.items():
            email = contact_info.get('email', '').strip().lower()
            if email:
                email_map[email] = entity_id
        
        return email_map
    
    def get_contact_by_email(self, email: str) -> Optional[Dict[str, Any]]:
        """Find a contact by email address."""
        if not self._email_to_person_map:
            self.refresh_cache()
        
        email_lower = email.strip().lower()
        entity_id = self._email_to_person_map.get(email_lower)
        
        if entity_id and self._contact_cache:
            return self._contact_cache.get(entity_id)
        
        return None
    
    def get_all_contacts(self) -> List[Dict[str, Any]]:
        """Get all contacts with their full information."""
        if not self._contact_cache:
            self.refresh_cache()
        
        return list(self._contact_cache.values()) if self._contact_cache else []
    
    def find_potential_duplicates(self) -> List[Tuple[str, str, str]]:
        """Find potential duplicate contacts based on similar names or shared emails."""
        if not self._contact_cache:
            self.refresh_cache()
        
        duplicates = []
        contacts_list = list(self._contact_cache.items())
        
        for i, (id1, contact1) in enumerate(contacts_list):
            for id2, contact2 in contacts_list[i+1:]:
                # Check for same email
                email1 = contact1.get('email', '').strip().lower()
                email2 = contact2.get('email', '').strip().lower()
                
                if email1 and email1 == email2:
                    duplicates.append((id1, id2, f"Same email: {email1}"))
                    continue
                
                # Check for similar names
                name1_lower = id1.lower()
                name2_lower = id2.lower()
                
                # Check if one name contains the other
                if name1_lower in name2_lower or name2_lower in name1_lower:
                    duplicates.append((id1, id2, "Similar names"))
                
                # Check if email address was used as a Person entity name
                if '@' in id1 and email2 and id1.lower() == email2:
                    duplicates.append((id1, id2, f"Email {id1} used as entity name"))
                elif '@' in id2 and email1 and id2.lower() == email1:
                    duplicates.append((id1, id2, f"Email {id2} used as entity name"))
        
        return duplicates
    
    def get_contact_context_prompt(self, max_contacts: int = 150) -> str:
        """Generate a comprehensive contact context prompt."""
        if not self._contact_cache:
            self.refresh_cache()
        
        if not self._contact_cache:
            return ""
        
        prompt_parts = [
            "=== EXISTING CONTACTS IN KNOWLEDGE GRAPH ===",
            "",
            "IMPORTANT: The following people already exist in the knowledge graph.",
            "You MUST use their EXACT entity ID when referencing them.",
            "DO NOT create new Person entities for these existing contacts!",
            "",
            "Format: [Entity ID] | Email: ... | Organization: ... | Description: ...",
            ""
        ]
        
        # Sort contacts by name for consistency
        sorted_contacts = sorted(self._contact_cache.items(), key=lambda x: x[0].lower())
        
        for i, (entity_id, contact) in enumerate(sorted_contacts[:max_contacts]):
            email = contact.get('email', 'N/A')
            org = contact.get('organization', 'N/A')
            desc = contact.get('description', 'N/A')
            
            # Truncate description if too long
            if len(desc) > 100:
                desc = desc[:97] + "..."
            
            prompt_parts.append(
                f"[{entity_id}] | Email: {email} | Org: {org} | Desc: {desc}"
            )
        
        if len(sorted_contacts) > max_contacts:
            prompt_parts.append(f"\n... and {len(sorted_contacts) - max_contacts} more contacts")
        
        prompt_parts.extend([
            "",
            "=== EMAIL HANDLING RULES ===",
            "",
            "1. Email addresses are NOT entities - they are properties of Person entities",
            "2. If you see an email address, check if a Person with that email already exists above",
            "3. If you find 'from: john@example.com', look for a Person with email 'john@example.com'",
            "4. If no existing Person has that email, create a new Person entity with a proper name",
            "5. NEVER create an entity with an email address as its ID (e.g., don't use 'john@example.com' as entity name)",
            "",
            "=== ENTITY MATCHING RULES ===",
            "",
            "When you encounter a person's name or email:",
            "1. First check the existing contacts list above",
            "2. Match by email if available (most reliable)",
            "3. Match by exact name if no email",
            "4. If unsure, prefer using an existing entity over creating a new one",
            "5. Use the EXACT entity ID from the list above (e.g., 'John Smith' not 'john smith')",
            ""
        ])
        
        return "\n".join(prompt_parts)
    
    def suggest_entity_name_from_email(self, email: str) -> str:
        """Suggest a proper entity name from an email address."""
        if not email or '@' not in email:
            return email
        
        # Extract the part before @
        local_part = email.split('@')[0]
        
        # Replace common separators with spaces
        name_parts = local_part.replace('.', ' ').replace('_', ' ').replace('-', ' ')
        
        # Capitalize each part
        name_parts = ' '.join(word.capitalize() for word in name_parts.split())
        
        return name_parts
    
    def merge_duplicate_contacts(self, primary_id: str, duplicate_id: str) -> bool:
        """Merge two duplicate Person entities (not implemented - for future use)."""
        # This would require updating all relationships from duplicate_id to primary_id
        # and then removing the duplicate entity
        logger.warning(f"Contact merge not yet implemented: {primary_id} <- {duplicate_id}")
        return False
