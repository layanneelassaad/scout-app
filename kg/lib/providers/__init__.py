"""Providers package for the knowledge graph system."""

class ProviderManager:
    """Manager for registering and executing commands."""
    
    def __init__(self):
        self.commands = {}
    
    def register_function(self, name, module_name, func, signature, docstring, flags):
        """Register a function as a command."""
        self.commands[name] = {
            'module': module_name,
            'function': func,
            'signature': signature,
            'docstring': docstring,
            'flags': flags
        }
    
    def get_command(self, name):
        """Get a registered command."""
        return self.commands.get(name)
    
    def list_commands(self):
        """List all registered commands."""
        return list(self.commands.keys()) 