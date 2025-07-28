from kg.lib.pipelines.pipe import pipe
import traceback

@pipe(name='filter_messages', priority=10)
async def filter_kg_messages(data: dict, context=None) -> dict:
    """Adds known persons from the knowledge graph to the system message."""
    try:
        if 'messages' not in data or not isinstance(data['messages'], list) or not data['messages']:
            return data

        if not hasattr(context, 'kg_list_by_type'):
            return data

        persons_result = await context.kg_list_by_type('Person')
        
        if not persons_result or not persons_result.get('success') or not persons_result.get('results'):
            return data

        persons = persons_result['results']

        if not persons:
            return data

        persons_list = []
        for p in persons:
            name = p.get('entity', 'Unknown')
            description = p.get('description', 'No description')
            persons_list.append(f"- {name}: {description}")

        if not persons_list:
            return data

        persons_text = "\n".join(persons_list)
        
        kg_content = f"""\n\n---\n**Known Persons:**\nThis is a list of persons known to the system. Refer to them when relevant.\n{persons_text}\n---"""

        if data['messages'][0]['role'] == 'system':
            system_message = data['messages'][0]
            if isinstance(system_message['content'], str):
                system_message['content'] += kg_content
            elif isinstance(system_message['content'], list):
                if system_message['content'] and system_message['content'][0].get('type') == 'text':
                    system_message['content'][0]['text'] += kg_content
                else:
                    system_message['content'].append({'type': 'text', 'text': kg_content})
            else:
                current_content = str(system_message['content'])
                system_message['content'] = f"{current_content}{kg_content}"
        
    except Exception as e:
        print(f"Error in filter_kg_messages pipe: {e}")
        traceback.print_exc()

    return data
