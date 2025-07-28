// SSE (Server-Sent Events) handler utility
// Extracted from chat.js for reuse in file search interface

export class SSEHandler {
    constructor(sessionId, options = {}) {
      this.sessionId = sessionId;
      this.options = options;
      this.eventSource = null;
      this.connected = false;
      this.eventHandlers = new Map();
    }
  
    connect() {
      if (this.eventSource) {
        this.eventSource.close();
      }
  
      const sseUrl = `/chat/${this.sessionId}/events`;
      this.eventSource = new EventSource(sseUrl);
  
      this.eventSource.onopen = () => {
        this.connected = true;
        console.log('SSE connected');
        this.emit('connected');
      };
  
      this.eventSource.onerror = () => {
        this.connected = false;
        console.log('SSE error');
        this.emit('error');
      };
  
      this.eventSource.onmessage = (event) => {
        try {
          const data = JSON.parse(event.data);
          this.emit('message', data);
        } catch (error) {
          console.error('Error parsing SSE message:', error);
        }
      };
  
      // Listen for specific event types
      ['partial_command', 'running_command', 'command_result', 'image', 'finished_chat'].forEach(eventType => {
        this.eventSource.addEventListener(eventType, (event) => {
          try {
            console.log(`Received ${eventType} event:`, event.data);
            const data = JSON.parse(event.data);
            this.emit(eventType, { ...data, event_type: eventType });
          } catch (error) {
            console.error(`Error parsing ${eventType} event:`, error);
          }
        });
      });
    }
  
    disconnect() {
      if (this.eventSource) {
        this.eventSource.close();
        this.eventSource = null;
      }
      this.connected = false;
    }
  
    on(eventName, handler) {
      if (!this.eventHandlers.has(eventName)) {
        this.eventHandlers.set(eventName, []);
      }
      this.eventHandlers.get(eventName).push(handler);
    }
  
    off(eventName, handler) {
      if (this.eventHandlers.has(eventName)) {
        const handlers = this.eventHandlers.get(eventName);
        const index = handlers.indexOf(handler);
        if (index > -1) {
          handlers.splice(index, 1);
        }
      }
    }
  
    emit(eventName, data) {
      if (this.eventHandlers.has(eventName)) {
        this.eventHandlers.get(eventName).forEach(handler => {
          try {
            handler(data);
          } catch (error) {
            console.error(`Error in event handler for ${eventName}:`, error);
          }
        });
      }
    }
  }