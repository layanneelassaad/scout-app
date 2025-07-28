# Knowledge Graph Plugin - Main Entry Point
# This import is currently required for the plugin to load properly
# Will be improved in future versions

from .graph_commands import *
from .file_commands import *
from .mod import *
from .consolidate_entities import *
from .router import *

# Import pipes to register them
from . import filter
