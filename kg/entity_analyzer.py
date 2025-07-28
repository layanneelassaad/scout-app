"""Entity analysis module"""

import os
import json
import logging
import re
import inspect
from typing import Dict, List, Any, Optional

from entity_types import get_entity_types_prompt
from contact_context import ContactContextManager
from line_format_parser import LineFormatParser

logger = logging.getLogger(__name__)

# BEGIN INLINE service_manager REPLACEMENT

class SimpleServiceManager:
    def __init__(self):
        self.functions = {}

    def register_function(self, name, module_name, func, signature, docstring, flags):
        self.functions[name] = {
            'module': module_name,
            'function': func,
            'signature': signature,
            'doc': docstring,
            'flags': flags
        }

    async def prompt(self, model_name, prompt_input):
        func = self.functions.get("prompt")
        if func is None:
            raise RuntimeError("Prompt function not registered.")
        return await func["function"](model_name, prompt_input)

service_manager = SimpleServiceManager()

def service(*, flags=[]):
    def decorator(func):
        docstring = func.__doc__
        name = func.__name__
        signature = inspect.signature(func)
        module = inspect.getmodule(func)
        if module is None:
            raise ValueError("Cannot determine module of function")
        module_name = os.path.basename(os.path.dirname(module.__file__))
        service_manager.register_function(name, module_name, func, signature, docstring, flags)
        return func
    return decorator

# END INLINE service_manager REPLACEMENT

class EntityAnalyzer:
    """Handles AI-based entity analysis for knowledge graph extraction."""
    
    def __init__(self, contact_context_manager: ContactContextManager):
        self.contact_context_manager = contact_context_manager
    
    async def analyze_file_content(self, content: str, file_metadata: Dict[str, Any], 
                                 file_entity_name: str) -> Optional[Dict[str, Any]]:
        """Analyze entire file content to extract high-level entities and relationships.
        
        Args:
            content: Full file content (limited to ~40KB)
            file_metadata: File metadata dictionary
            file_entity_name: Name of the file entity in the graph
        """
        if not content.strip():
            return None
        print('analyze_file_content')        
        # Get entity types prompt with full list of available types
        entity_types_prompt = get_entity_types_prompt()
        print('1')
        # Get comprehensive contact context
        self.contact_context_manager.refresh_cache()
        contacts_context = self.contact_context_manager.get_contact_context_prompt(max_contacts=150)
        print('2')
        # Build simplified analysis prompt focused on high-level entities
        instructions = self._build_analysis_prompt(
            entity_types_prompt, contacts_context, file_metadata, file_entity_name, content
        )
        print('3')
        try:
            result_str = await service_manager.prompt(
                os.environ.get("MR_KG_ANALYZE_LLM", "models/gemini-2.5-flash-lite-preview-06-17"),
                instructions
            )
            print('4')
            if result_str and isinstance(result_str, str):
                print('4a')
                # Parse line-based format instead of JSON
                result = LineFormatParser.parse(result_str)
                return self._process_analysis_result(result)
            print('5')
            logger.warning(f"KG analysis returned non-string or empty result: {result_str}")
            return None
            
        except ValueError as e:
            logger.error(f"Failed to parse line format from analyzer agent: {e}. Result was: {result_str}")
            return None
        except json.JSONDecodeError as e:
            logger.error(f"Failed to process result: {e}. Result was: {result_str}")
            return None
        except Exception as e:
            logger.error(f"Error during AI analysis task: {e}")
            return None
    
    def _build_analysis_prompt(self, entity_types_prompt: str, contacts_context: str, 
                             file_metadata: Dict[str, Any], file_entity_name: str, 
                             content: str) -> str:
        """Build the analysis prompt for high-level entity extraction."""
        # Get line format instructions
        format_instructions = LineFormatParser.format_instructions()
        format_example = LineFormatParser.format_example()
        return (
            "=== KNOWLEDGE GRAPH EXTRACTION TASK ===\n\n" +
            entity_types_prompt + "\n\n" +
            f'File context: {file_metadata.get("file_name", "unknown")} ' +
            f'({file_metadata.get("file_extension", "unknown type")})\n' +
            f'File path: {file_metadata.get("full_path", "unknown")}\n' +
            f'File entity name: {file_entity_name}\n' +
            "\n" + contacts_context + "\n\n" +
            'ANALYSIS INSTRUCTIONS:\n' +
            'Analyze the following document content to identify the MAIN, HIGH-LEVEL entities and relationships.\n' +
            'Focus on:\n' +
            '- Key people mentioned\n' +
            '- Important organizations and companies\n' +
            '- Major topics, projects, or concepts\n' +
            '- Significant dates and events\n' +
            '- Document purpose and key relationships\n\n' +
            'DO NOT extract every minor detail. Focus on entities that would be useful for casual searches.\n' +
            'Aim for 5-15 key entities per document, not exhaustive extraction.\n\n' +
            'CRITICAL RULES FOR PERSON ENTITIES:\n' +
            '1. Check the existing contacts list above BEFORE creating any Person entity\n' +
            '2. Use EXACT entity IDs from the existing contacts list when available\n' +
            '3. NEVER modify entity names with brackets [], [[]], or any other decorations\n' +
            '4. NEVER use email addresses as entity IDs\n' +
            '5. If you see an email, check if a Person with that email already exists\n' +
            '6. When referencing an existing person, use their EXACT name as shown in the list\n' +
            '7. DO NOT add brackets or any other characters to differentiate multiple mentions\n' +
            '8. If "John Smith" exists in the list, ALWAYS use "John Smith", never "[John Smith]"\n\n' +
            'ENTITY NAME RULES:\n' +
            '- Use the exact name as it appears in the existing contacts list\n' +
            '- Do not add brackets, parentheses, or any other modifications\n' +
            '- If the same person is mentioned multiple times, use the same exact entity ID each time\n' +
            '- Brackets like [name] or [[name]] are FORBIDDEN and will cause errors\n\n' +
            '=== OUTPUT FORMAT ===\n\n' +
            format_instructions + '\n\n' +
            'Example output:\n' +
            format_example + '\n\n' +
            '=== DOCUMENT CONTENT TO ANALYZE ===\n\n' + 
            content
        )
    
    def _strip_brackets(self, name: str) -> str:
        """Remove brackets from entity names."""
        # Remove all brackets [], [[]], [[[]]], etc.
        cleaned = re.sub(r'^\[+|\]+$', '', name)
        return cleaned.strip()
    
    def _process_analysis_result(self, result: Dict[str, Any]) -> Dict[str, Any]:
        """Process and validate the analysis result."""
        # Validate and fix entity names
        for entity in result.get('entities', []):
            original_name = entity['name']
            
            # Strip brackets from all entity names, not just Person
            cleaned_name = self._strip_brackets(original_name)
            if cleaned_name != original_name:
                logger.warning(f"Stripped brackets from entity name: '{original_name}' -> '{cleaned_name}'")
                entity['name'] = cleaned_name
            
            if entity.get('type') == 'Person':
                entity_name = entity['name']
                
                # Check if entity name is an email address
                if '@' in entity_name:
                    # Try to find existing person with this email
                    existing_contact = self.contact_context_manager.get_contact_by_email(entity_name)
                    if existing_contact:
                        # Replace with existing entity ID
                        entity['name'] = existing_contact['id']
                        logger.info(f"Replaced email entity '{entity_name}' with existing contact '{existing_contact['id']}'")
                    else:
                        # Generate proper name from email
                        suggested_name = self.contact_context_manager.suggest_entity_name_from_email(entity_name)
                        entity['name'] = suggested_name
                        # Add email as a property
                        if 'properties' not in entity:
                            entity['properties'] = {}
                        entity['properties']['email'] = entity_name
                        logger.info(f"Converted email entity '{entity_name}' to proper name '{suggested_name}'")
                else:
                    # Check if this exact person already exists
                    all_contacts = self.contact_context_manager.get_all_contacts()
                    for contact in all_contacts:
                        if contact['id'].lower() == entity_name.lower():
                            # Use the exact case from the existing entity
                            if contact['id'] != entity_name:
                                logger.info(f"Corrected entity name case: '{entity_name}' -> '{contact['id']}'")
                                entity['name'] = contact['id']
                            break
        
        # Fix relationship targets/sources that might be email addresses or have brackets
        for rel in result.get('relationships', []):
            # Strip brackets from relationship source and target
            original_source = rel['source']
            original_target = rel['target']
            
            rel['source'] = self._strip_brackets(original_source)
            rel['target'] = self._strip_brackets(original_target)
            
            if rel['source'] != original_source:
                logger.warning(f"Stripped brackets from relationship source: '{original_source}' -> '{rel['source']}'")
            if rel['target'] != original_target:
                logger.warning(f"Stripped brackets from relationship target: '{original_target}' -> '{rel['target']}'")
            
            # Fix email addresses in relationships
            if '@' in rel['target']:
                existing_contact = self.contact_context_manager.get_contact_by_email(rel['target'])
                if existing_contact:
                    logger.info(f"Fixed relationship target from email '{rel['target']}' to '{existing_contact['id']}'")
                    rel['target'] = existing_contact['id']
            if '@' in rel['source']:
                existing_contact = self.contact_context_manager.get_contact_by_email(rel['source'])
                if existing_contact:
                    logger.info(f"Fixed relationship source from email '{rel['source']}' to '{existing_contact['id']}'")
                    rel['source'] = existing_contact['id']
        
        return result
