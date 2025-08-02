from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel
import os
import json
from typing import List, Dict, Any, Optional
from .lib.route_decorators import requires_role, public_route
from datetime import datetime
import asyncio
from pathlib import Path
from .lib.utils.debug import debug_box

router = APIRouter()
from fastapi.responses import StreamingResponse
import uuid
import time
import asyncio
from typing import Union

# Temporary in-memory session storage (for simplicity)
sessions = {}

# Generate a session (this replaces your /makesession/kg2)
@router.get("/makesession/kg2")
async def create_session(api_key: str):
    log_id = str(uuid.uuid4())
    sessions[log_id] = {
        "log_id": log_id,
        "created_at": time.time(),
        "commands": []
    }
    return {"log_id": log_id}

@router.get("/chat/{session_id}/events")
async def stream_events(session_id: str, api_key: str):
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found")

    async def event_generator():
        # Send thinking events
        for i in range(3):
            await asyncio.sleep(1)
            yield f"event: partial_command\ndata: {{\"command\": \"searching\", \"args\": {{\"step\": \"{i+1}\"}} }}\n\n"
        
        # Send search results
        search_results = sessions[session_id].get("search_results", [])
        if search_results:
            for result in search_results[:5]:  # Limit to 5 results
                await asyncio.sleep(0.5)
                yield f"event: command_result\ndata: {{\"result\": {{\"entity\": \"{result.get('entity', 'Unknown')}\", \"score\": {result.get('score', 0.0)}, \"type\": \"{result.get('type', 'Unknown')}\", \"description\": \"{result.get('description', '')}\"}} }}\n\n"
        else:
            # Fallback to demo result if no search results
            await asyncio.sleep(0.5)
            yield f"event: command_result\ndata: {{\"result\": {{\"entity\": \"/Users/demo/example.pdf\", \"score\": 0.8, \"type\": \"document\", \"description\": \"Demo document\"}} }}\n\n"
        
        await asyncio.sleep(1)
        yield f"event: finished_chat\ndata: {{}}\n\n"

    return StreamingResponse(event_generator(), media_type="text/event-stream")

class MessageInput(BaseModel):
    type: str
    text: str

@router.post("/chat/{session_id}/send")
async def send_query(session_id: str, messages: List[MessageInput], api_key: str):
    if session_id not in sessions:
        raise HTTPException(status_code=404, detail="Session not found")

    for message in messages:
        sessions[session_id]["commands"].append(message.text)
        print(f"[Session {session_id}] Message received: {message.text}")
        
        # Perform actual search using the kg_search function
        try:
            from .graph_commands import kg_search
            search_result = await kg_search(
                query=message.text,
                limit=10,
                semantic=False,
                threshold=0.7
            )
            
            if search_result.get('success'):
                # Store the search results in the session
                sessions[session_id]["search_results"] = search_result.get('results', [])
                print(f"Search completed with {len(search_result.get('results', []))} results")
                print(f"Search results: {search_result.get('results', [])}")
            else:
                print(f"Search failed: {search_result.get('error', 'Unknown error')}")
                
        except Exception as e:
            print(f"Error performing search: {e}")

    return {"status": "received", "message_count": len(messages)}


# Import command functions instead of duplicating functionality
from .file_commands import (
    kg_index_directory,
    kg_add_watched_directory,
    kg_remove_watched_directory,
    kg_list_watched_directories,
    kg_run_scheduled_indexing,
    kg_open_file
)
from .graph_commands import kg_get_stats
from .mod import get_indexing_in_progress


# Set up Jinja2 templates for the home page
templates = Jinja2Templates(directory=os.path.join(os.path.dirname(__file__), "templates"))

protected_router = APIRouter(
    dependencies=[requires_role('user')]
)

class WatchedDirectory(BaseModel):
    path: str
    schedule: str = 'hourly'
    status: str = 'inactive'
    last_indexed: Optional[datetime] = None
    file_count: int = 0
    error_message: Optional[str] = None

class AddWatchedDirRequest(BaseModel):
    path: str
    schedule: str = 'hourly'

class RemoveWatchedDirRequest(BaseModel):
    path: str

class IndexDirectoryRequest(BaseModel):
    path: str

# Add the file search page route
from fastapi.responses import HTMLResponse


@router.get('/firebird', response_class=HTMLResponse)
async def filesearch_page(request:Request):
    """Render the file search page."""
    try:
        return templates.TemplateResponse("filesearch.jinja2", {"request": request})
        # Get access token for the user
        #access_token = getattr(request.state, 'access_token', '')
        
        #return await render('filesearch', {
        #    'request': request,
        #    'access_token': access_token
        #})
    except Exception as e:
        return HTMLResponse(
            content=f"<h1>Error</h1><p>Failed to load file search page: {str(e)}</p>",
            status_code=500
        )

debug_box("Loaded Knowledge Graph API routes successfully.")



@protected_router.get('/api/kg/watched-dirs')
async def get_watched_dirs():
    """Get list of watched directories."""
    try:

        print('............................................')
        print("Fetching watched directories...")
        result = await kg_list_watched_directories()
        
        if result.get('success'):
            return JSONResponse({
                'success': True,
                'data': result.get('watched_directories', [])
            })
        else:
            return JSONResponse({
                'success': False,
                'error': result.get('error', 'Unknown error')
            }, status_code=500)
            
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

@protected_router.post('/api/kg/add-watched-dir')
async def add_watched_dir(request: AddWatchedDirRequest):
    """Add a directory to the watch list."""
    try:
        result = await kg_add_watched_directory(
            path=request.path,
            schedule=request.schedule
        )
        
        if result.get('success'):
            return JSONResponse({
                'success': True,
                'message': result.get('message', 'Directory added successfully')
            })
        else:
            return JSONResponse({
                'success': False,
                'error': result.get('error', 'Unknown error')
            }, status_code=400)
            
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

@protected_router.post('/api/kg/remove-watched-dir')
async def remove_watched_dir(request: RemoveWatchedDirRequest):
    """Remove a directory from the watch list."""
    try:
        result = await kg_remove_watched_directory(path=request.path)
        
        if result.get('success'):
            return JSONResponse({
                'success': True,
                'message': result.get('message', 'Directory removed successfully')
            })
        else:
            return JSONResponse({
                'success': False,
                'error': result.get('error', 'Unknown error')
            }, status_code=400)
            
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

@protected_router.post('/api/kg/index-directory')
async def index_directory(request: IndexDirectoryRequest):
    """Manually trigger indexing of a directory."""
    try:
        # Check if directory is already being indexed using shared state
        indexing_in_progress = get_indexing_in_progress()
        if request.path in indexing_in_progress:
            return JSONResponse({
                'success': False,
                'error': 'Directory is already being indexed. Please wait for the current operation to complete.'
            }, status_code=409)
        
        # Use the command function instead of duplicating logic
        result = await kg_index_directory(
            path=request.path,
            recursive=True,
            file_extensions=None  # Use defaults
        )
        
        if result.get('success'):
            return JSONResponse({
                'success': True,
                'files_processed': result.get('files_processed', 0),
                'files_skipped': result.get('files_skipped', 0),
                'errors': result.get('errors', []),
                'total_errors': result.get('total_errors', 0),
                'message': result.get('message', 'Directory indexed successfully')
            })
        else:
            return JSONResponse({
                'success': False,
                'error': result.get('error', 'Unknown error')
            }, status_code=500)
            
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

@protected_router.get('/api/kg/stats')
async def get_kg_stats_api():
    """Get knowledge graph statistics."""
    try:
        result = await kg_get_stats()
        
        if result.get('success'):
            # Format the response for the API
            graph_stats = result.get('graph', {})
            embedding_stats = result.get('embeddings', {})
            
            return JSONResponse({
                'success': True,
                'data': {
                    'total_entities': graph_stats.get('num_entities', 0),
                    'total_relationships': graph_stats.get('num_relationships', 0),
                    'indexed_files': embedding_stats.get('num_embeddings', 0),
                    'graph_stats': graph_stats,
                    'embedding_stats': embedding_stats
                }
            })
        else:
            return JSONResponse({
                'success': False,
                'error': result.get('error', 'Unknown error')
            }, status_code=500)
            
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

@protected_router.post('/api/kg/run-scheduled')
async def run_scheduled_indexing():
    """Run scheduled indexing for all watched directories."""
    try:
        result = await kg_run_scheduled_indexing()
        
        return JSONResponse({
            'success': result.get('success', False),
            'processed': result.get('processed', []),
            'errors': result.get('errors', []),
            'message': result.get('message', 'Scheduled indexing completed')
        })
        
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

@protected_router.get('/api/kg/indexing-status')
async def get_indexing_status():
    """Get current indexing operations status."""
    try:
        indexing_in_progress = get_indexing_in_progress()
        
        return JSONResponse({
            'success': True,
            'data': {
                'indexing_in_progress': list(indexing_in_progress),
                'active_operations': len(indexing_in_progress)
            }
        })
        
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)


class ListFilesRequest(BaseModel):
    query: Optional[str] = None
    limit: int = 20
    semantic: bool = True
    threshold: float = 0.7

class OpenFileRequest(BaseModel):
    file_path: str


@router.post('/api/kg/open-file')
async def open_file_api(request: OpenFileRequest):
    """Open a file using the system's default application."""
    try:
        print(f"Opening file: {request.file_path}")
        result = await kg_open_file(file_path=request.file_path)
        
        if result.get('success'):
            return JSONResponse({
                'success': True,
                'message': result.get('message', 'File opened successfully'),
                'file_path': result.get('file_path')
            })
        else:
            return JSONResponse({
                'success': False,
                'error': result.get('error', 'Unknown error')
            }, status_code=400)
            
    except Exception as e:
        return JSONResponse({
            'success': False,
            'error': str(e)
        }, status_code=500)

router.include_router(protected_router)
