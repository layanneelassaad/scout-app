"""File indexing and directory management commands."""

import os
import json
import logging
import traceback
from typing import Dict, List, Any, Optional
from datetime import datetime, timedelta
from kg.lib.providers.commands import command
from kg.lib.providers.services import service_manager
import platform
import subprocess


from .mod import _get_graph_store, _get_embedding_manager, _get_query_engine, _get_file_indexer, get_indexing_in_progress

logger = logging.getLogger(__name__)

@command()
async def kg_list_file(file_path, context=None):
    """Add a relevant result file to the file list in the search UI for the user.
       Use this immediately once you have found the file or files most relevant to
       the user's query.

    Args:
        file_path: the absolute path to the file

    Example:
        {"kg_list_file": {
            "full_path": "/test/myfile.txt"
        }}
    
    """
    file_reeult = {}
    if file_path and os.path.exists(file_path):
        # Get file stats
        try:
            stat_info = os.stat(file_path)
            file_size = stat_info.st_size
            last_modified = datetime.fromtimestamp(stat_info.st_mtime)
            
            # Format file size
            if file_size < 1024:
                size_str = f"{file_size} B"
            elif file_size < 1024 * 1024:
                size_str = f"{file_size / 1024:.1f} KB"
            elif file_size < 1024 * 1024 * 1024:
                size_str = f"{file_size / (1024 * 1024):.1f} MB"
            else:
                size_str = f"{file_size / (1024 * 1024 * 1024):.1f} GB"
            
        except OSError:
            file_size = 0
            size_str = "Unknown"
            last_modified = None
        
        file_result = {
            'path': file_path,
            'file_size': file_size,
            'size_str': size_str,
            'last_modified': last_modified.isoformat() if last_modified else None,
            'last_modified_str': last_modified.strftime('%Y-%m-%d %H:%M') if last_modified else 'Unknown'
        }
    
    return {
        'success': True,
        'file': file_result
    }

@command()
async def kg_open_file(file_path, context=None):
    """Open a file using the system's default application.
    
    This command opens a file with the system's default application using xdg-open.
    The file path should be the full absolute path to the file you want to open.
    
    Args:
        file_path: Full absolute path to the file to open
    
    Returns:
        Dictionary with success status and message
    
    Examples:
        # Open a PDF document
        {"kg_open_file": {
            "file_path": "/home/user/documents/report.pdf"
        }}
        
        # Open a text file
        {"kg_open_file": {
            "file_path": "/home/user/code/main.py"
        }}
        
        # Open an image
        {"kg_open_file": {
            "file_path": "/home/user/images/screenshot.png"
        }}
    
    The file will open in the system's default application for that file type.
    For example, PDFs will open in the default PDF viewer, images in the image viewer, etc.
    """
    try:
        if not os.path.exists(file_path):
            return {
                'success': False,
                'error': f'File not found: {file_path}'
            }
        import webbrowser
        
        print("Opening file:", file_path)
        system = platform.system()
        print("System detected:", system)

        if system == 'Darwin':  # macOS
            subprocess.Popen(['open', file_path])
        elif system == 'Windows':
            os.startfile(file_path)
        else:
            import subprocess
            subprocess.run(['env', '-i', 'DISPLAY=' + os.environ.get('DISPLAY', ':0'), 
                        'HOME=' + os.environ.get('HOME'), 
                        'USER=' + os.environ.get('USER'),
                        'xdg-open', file_path])

            #os.environ.pop('QT_PLUGIN_PATH', None)

        return {
            'success': True,
            'file_path': file_path,
            'message': f'Opened file: {os.path.basename(file_path)}'
        }
       
    except subprocess.TimeoutExpired:
        return {
            'success': False,
            'error': 'Timeout opening file'
        }
    except Exception as e:
        logger.error(f"Error opening file: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_index_file(file_path, chunk_size=2000, overlap=200, extract_entities=True, auto_analyze=True, context=None):
    """Index a file and extract knowledge graph information.
    
    Args:
        file_path: Path to the file to index
        chunk_size: Maximum size of text chunks
        overlap: Overlap between chunks
        extract_entities: Whether to extract entities automatically
        auto_analyze: Whether to use AI agent for analysis
    
    Example:
        {"kg_index_file": {
            "file_path": "/path/to/document.pdf",
            "chunk_size": 2000,
            "extract_entities": true,
            "auto_analyze": true
        }}
    """
    try:
        file_indexer = _get_file_indexer()
        
        result = await file_indexer.index_file(
            file_path=file_path,
            chunk_size=chunk_size,
            overlap=overlap,
            extract_entities=extract_entities,
            auto_analyze=auto_analyze
        )
        
        return result
        
    except Exception as e:
        logger.error(f"Error indexing file: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_index_directory(path, recursive=True, file_extensions=None, context=None):
    """Index all files in a directory.
    
    Args:
        path: Directory path to index
        recursive: Whether to index subdirectories
        file_extensions: List of file extensions to index (default: common text files)
    
    Example:
        {"kg_index_directory": {
            "path": "/home/user/documents",
            "recursive": true,
            "file_extensions": [".txt", ".md", ".py"]
        }}
    """
    try:
        if not os.path.exists(path):
            return {
                'success': False,
                'error': 'Directory does not exist'
            }
        
        if not os.path.isdir(path):
            return {
                'success': False,
                'error': 'Path is not a directory'
            }
        
        # Check if this directory is already being indexed
        indexing_in_progress = get_indexing_in_progress()
        if path in indexing_in_progress:
            return {
                'success': False,
                'error': 'Directory is already being indexed. Please wait for the current indexing to complete.'
            }
        
        # Mark directory as being indexed
        indexing_in_progress.add(path)
        
        try:
            # Default file extensions to index
            if file_extensions is None:
                file_extensions = ['.txt', '.md', '.py', '.js', '.html', '.css', '.json', '.xml', '.csv', '.rst', '.tex', '.eml']
            
            file_indexer = _get_file_indexer()
            
            files_processed = 0
            files_skipped = 0
            errors = []
            
            ignored_dirs = {'.git', '__pycache__'}
            
            # Walk through directory
            for root, dirs, files in os.walk(path):
                # Modify dirs in-place to exclude ignored directories
                dirs[:] = [d for d in dirs if d not in ignored_dirs]
                
                if not recursive and root != path:
                    break
                
                for file in files:
                    # Ignore dotfiles
                    if file.startswith('.'):
                        files_skipped += 1
                        continue
                    
                    file_path = os.path.join(root, file)
                    
                    # Check file extension
                    _, ext = os.path.splitext(file.lower())
                    if ext not in file_extensions:
                        files_skipped += 1
                        continue
                    
                    try:
                        for _ in range(6):
                            print()
            
                        print('-----------------------------------------------------')
                        print("Indexing file:", file_path)
                        print("Total files processed:", files_processed)

                        result = await file_indexer.index_file(
                            file_path=file_path,
                            chunk_size=2000,
                            overlap=200,
                            extract_entities=True,
                            auto_analyze=True
                        )
                        if result.get('success'):
                            files_processed += 1
                        else:
                            errors.append(f"{file_path}: {result.get('error', 'Unknown error')}")
                    except Exception as e:
                        print("ERROR")
                        trace = traceback.format_exc()
                        print(e)
                        print(trace)
                        errors.append(f"{file_path}: {str(e)}")
            
            print('done -----------------------------------------------------')
            print(errors)

           
            # Update watched directory info if it exists
            watched_dirs_file = '/tmp/kg_watched_dirs.json'
            if os.path.exists(watched_dirs_file):
                try:
                    with open(watched_dirs_file, 'r') as f:
                        watched_dirs = json.load(f)
                    
                    for dir_info in watched_dirs:
                        if dir_info['path'] == path:
                            dir_info['last_indexed'] = datetime.now().isoformat()
                            dir_info['status'] = 'active'
                            break
                    
                    with open(watched_dirs_file, 'w') as f:
                        json.dump(watched_dirs, f, indent=2, default=str)
                except Exception as ee:
                    trace2 = traceback.format_exc()
                    print(f"Error updating watched directories: {ee}\n{trace2}")
                    print("Aborting")
                    return
            
            return {
                'success': True,
                'files_processed': files_processed,
                'files_skipped': files_skipped,
                'errors': errors[:10],  # Limit to first 10 errors
                'total_errors': len(errors),
                'message': f'Indexed {files_processed} files from {path}'
            }
        
        finally:
            # Always remove from indexing set, even if there was an error
            indexing_in_progress.discard(path)

        print("Done")
        
    except Exception as e:
        logger.error(f"Error indexing directory: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_add_watched_directory(path, schedule='hourly', context=None):
    """Add a directory to the watch list for automatic indexing.
    
    Args:
        path: Directory path to watch
        schedule: Indexing schedule ('manual', 'hourly', 'daily', 'weekly')
    
    Example:
        {"kg_add_watched_directory": {
            "path": "/home/user/documents",
            "schedule": "daily"
        }}
    """
    try:
        if not os.path.exists(path):
            return {
                'success': False,
                'error': 'Directory does not exist'
            }
        
        if not os.path.isdir(path):
            return {
                'success': False,
                'error': 'Path is not a directory'
            }
        
        # Load existing watched directories
        watched_dirs_file = '/tmp/kg_watched_dirs.json'
        watched_dirs = []
        
        if os.path.exists(watched_dirs_file):
            try:
                with open(watched_dirs_file, 'r') as f:
                    watched_dirs = json.load(f)
            except Exception:
                watched_dirs = []
        
        # Check if directory is already being watched
        for existing_dir in watched_dirs:
            if existing_dir['path'] == path:
                return {
                    'success': False,
                    'error': 'Directory is already being watched'
                }
        
        # Add new directory
        new_dir = {
            'path': path,
            'schedule': schedule,
            'status': 'active',
            'last_indexed': None,
            'added_at': datetime.now().isoformat()
        }
        
        watched_dirs.append(new_dir)
        
        # Save updated list
        with open(watched_dirs_file, 'w') as f:
            json.dump(watched_dirs, f, indent=2, default=str)
        
        return {
            'success': True,
            'message': f'Added directory {path} to watch list with {schedule} schedule'
        }
        
    except Exception as e:
        logger.error(f"Error adding watched directory: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_remove_watched_directory(path, context=None):
    """Remove a directory from the watch list.
    
    Args:
        path: Directory path to remove from watch list
    
    Example:
        {"kg_remove_watched_directory": {
            "path": "/home/user/documents"
        }}
    """
    try:
        watched_dirs_file = '/tmp/kg_watched_dirs.json'
        watched_dirs = []
        
        if os.path.exists(watched_dirs_file):
            try:
                with open(watched_dirs_file, 'r') as f:
                    watched_dirs = json.load(f)
            except Exception:
                watched_dirs = []
        
        # Remove the directory
        original_count = len(watched_dirs)
        watched_dirs = [d for d in watched_dirs if d['path'] != path]
        
        if len(watched_dirs) == original_count:
            return {
                'success': False,
                'error': 'Directory not found in watch list'
            }
        
        # Save updated list
        with open(watched_dirs_file, 'w') as f:
            json.dump(watched_dirs, f, indent=2, default=str)
        
        return {
            'success': True,
            'message': f'Removed directory {path} from watch list'
        }
        
    except Exception as e:
        logger.error(f"Error removing watched directory: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_list_watched_directories(context=None):
    """List all watched directories and their status.
    
    Example:
        {"kg_list_watched_directories": {}}
    """
    try:
        watched_dirs_file = '/tmp/kg_watched_dirs.json'
        watched_dirs = []
        
        if os.path.exists(watched_dirs_file):
            try:
                with open(watched_dirs_file, 'r') as f:
                    watched_dirs = json.load(f)
            except Exception:
                watched_dirs = []
        
        # Update status for each directory
        for dir_info in watched_dirs:
            if os.path.exists(dir_info['path']):
                dir_info['status'] = 'active'
                # Count files
                file_count = 0
                try:
                    for root, dirs, files in os.walk(dir_info['path']):
                        file_count += len(files)
                    dir_info['file_count'] = file_count
                except Exception:
                    dir_info['file_count'] = 0
            else:
                dir_info['status'] = 'error'
                dir_info['error_message'] = 'Directory not found'
        
        return {
            'success': True,
            'watched_directories': watched_dirs
        }
        
    except Exception as e:
        logger.error(f"Error listing watched directories: {e}")
        return {
            'success': False,
            'error': str(e)
        }

@command()
async def kg_run_scheduled_indexing(context=None):
    """Run scheduled indexing for all watched directories.
    
    This command checks all watched directories and indexes those that are due
    for indexing based on their schedule.
    
    Example:
        {"kg_run_scheduled_indexing": {}}
    """
    try:
        watched_dirs_file = '/tmp/kg_watched_dirs.json'
        if not os.path.exists(watched_dirs_file):
            return {
                'success': True,
                'message': 'No watched directories configured',
                'processed': []
            }
        
        with open(watched_dirs_file, 'r') as f:
            watched_dirs = json.load(f)
        
        processed = []
        errors = []
        
        for dir_info in watched_dirs:
            try:
                # Skip manual-only directories
                if dir_info.get('schedule') == 'manual':
                    continue
                
                # Check if directory exists
                if not os.path.exists(dir_info['path']):
                    dir_info['status'] = 'error'
                    dir_info['error_message'] = 'Directory not found'
                    continue
                
                # Determine if indexing is due
                last_indexed = dir_info.get('last_indexed')
                schedule = dir_info.get('schedule', 'daily')
                
                should_index = False
                
                if last_indexed is None:
                    should_index = True
                else:
                    try:
                        last_indexed_dt = datetime.fromisoformat(last_indexed.replace('Z', '+00:00'))
                        now = datetime.now()
                        
                        if schedule == 'hourly':
                            should_index = (now - last_indexed_dt) >= timedelta(hours=1)
                        elif schedule == 'daily':
                            should_index = (now - last_indexed_dt) >= timedelta(days=1)
                        elif schedule == 'weekly':
                            should_index = (now - last_indexed_dt) >= timedelta(weeks=1)
                    except Exception:
                        should_index = True  # If we can't parse the date, index anyway
                
                if should_index:
                    # Index the directory
                    result = await kg_index_directory(dir_info['path'], context=context)
                    if result.get('success'):
                        processed.append({
                            'path': dir_info['path'],
                            'files_processed': result.get('files_processed', 0),
                            'status': 'success'
                        })
                        dir_info['last_indexed'] = datetime.now().isoformat()
                        dir_info['status'] = 'active'
                    else:
                        errors.append(f"{dir_info['path']}: {result.get('error', 'Unknown error')}")
                        dir_info['status'] = 'error'
                        dir_info['error_message'] = result.get('error', 'Unknown error')
                        
            except Exception as e:
                errors.append(f"{dir_info['path']}: {str(e)}")
                dir_info['status'] = 'error'
                dir_info['error_message'] = str(e)
        
        # Save updated directory info
        with open(watched_dirs_file, 'w') as f:
            json.dump(watched_dirs, f, indent=2, default=str)
        
        return {
            'success': True,
            'processed': processed,
            'errors': errors,
            'message': f'Processed {len(processed)} directories, {len(errors)} errors'
        }
        
    except Exception as e:
        logger.error(f"Error running scheduled indexing: {e}")
        return {
            'success': False,
            'error': str(e)
        }