// Command handler utility
// Extracted from chat.js for reuse in file search interface

const commandHandlers = {};

// Function to register command handlers
export function registerCommandHandler(command, handler) {
  console.log("Registering command handler for", command);
  commandHandlers[command] = handler;
}

// Function to get a command handler
export function getCommandHandler(command) {
  return commandHandlers[command];
}

// Function to handle command events
export async function handleCommandEvent(data) {
  const handler = commandHandlers[data.command];
  if (handler) {
    try {
      return await handler(data);
    } catch (error) {
      console.error(`Error in command handler for ${data.command}:`, error);
      return null;
    }
  } else {
    console.warn('No handler for command:', data.command);
    return null;
  }
}

// Export for global access (backward compatibility)
if (typeof window !== 'undefined') {
  window.registerCommandHandler = registerCommandHandler;
}

// Register default handlers for file operations
registerCommandHandler('kg_list_files', (data) => {
  if (data.event === 'result') {
    // Update file list component if it exists
    const fileList = document.querySelector('kg-file-list');
    if (fileList && data.args.success) {
      fileList.files = data.args.files || [];
      fileList.loading = false;
    }
    return null; // Don't show in chat
  }
  return null;
});

registerCommandHandler('kg_open_file', (data) => {
  if (data.event === 'result') {
    const result = data.args;
    if (result.success) {
      return `<div style="color: #4CAF50;">✓ Opened file: ${result.file_path}</div>`;
    } else {
      return `<div style="color: #f44336;">Failed to open file: ${result.error}</div>`;
    }
  }
  return null;
});
