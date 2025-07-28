import { LitElement, html, css } from '/chat/static/js/lit-core.min.js';
import { BaseEl } from '/chat/static/js/base.js';
import { SSEHandler } from './sse-handler.js';
import { registerCommandHandler, handleCommandEvent } from './command-handler.js';

class KgFileSearch extends BaseEl {
  static properties = {
    files: { type: Array },
    loading: { type: Boolean },
    query: { type: String },
    searchResults: { type: Array },
    connected: { type: Boolean },
    searching: { type: Boolean }
  };

  static styles = css`
    :host {
      display: block;
      width: 100%;
      height: 100vh;
      background: var(--component-bg, var(--background-color));
      color: var(--component-text, var(--text-color));
      padding: 1rem;
      box-sizing: border-box;
    }

    .search-container {
      max-width: 1200px;
      margin: 0 auto;
      display: flex;
      flex-direction: column;
      height: 100%;
    }

    .search-header {
      margin-bottom: 2rem;
    }

    .search-title {
      font-size: 2rem;
      font-weight: 600;
      margin-bottom: 0.5rem;
      color: var(--text-color);
    }

    .search-subtitle {
      font-size: 1rem;
      opacity: 0.7;
      margin-bottom: 1.5rem;
    }

    .search-status {
      display: flex;
      align-items: flex-start;
      justify-content: left;
      margin-bottom: 1rem;
      color: var(--text-color);
      font-size: 0.9rem;
      opacity: 0.8;
    }

    .spinner {
      border: 2px solid rgba(255, 255, 255, 0.1);
      border-top: 2px solid rgba(255, 255, 255, 0.5);
      border-radius: 50%;
      width: 24px;
      height: 24px;
      animation: spin 1s linear infinite;
      margin: 0 auto;
    }

    .status {
      font-size: 0.9rem;
      color: var(--text-color);
      margin-bottom: 3rem;
      opacity: 0.8;
      display: flex;
      flex-direction: column;
      gap: 0.25rem;
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 8px;
      white-space: nowrap;
      text-overflow: ellipsis;
      overflow: hidden;
    }

    .search-input-container {
      position: relative;
      margin-bottom: 1rem;
    }

    .search-input {
      width: 100%;
      padding: 1rem 1.5rem;
      font-size: 1.1rem;
      background: rgba(0, 0, 0, 0.2);
      border: 2px solid rgba(255, 255, 255, 0.1);
      border-radius: 12px;
      color: var(--text-color);
      outline: none;
      transition: border-color 0.2s;
    }

    .search-input:focus {
      border-color: rgba(255, 255, 255, 0.3);
    }

    .search-input::placeholder {
      color: rgba(255, 255, 255, 0.5);
    }

    .connection-status {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-size: 0.9rem;
      margin-bottom: 1rem;
      opacity: 0.7;
    }

    .connection-status.connected {
      color: #4CAF50;
    }

    .connection-status.disconnected {
      color: #f44336;
    }

    .file-list-container {
      flex: 1;
      overflow-y: auto;
      background: rgba(0, 0, 0, 0.1);
      border-radius: 8px;
      border: 1px solid rgba(255, 255, 255, 0.1);
    }

    .file-list {
      padding: 0;
      margin: 0;
    }

    .file-item {
      display: flex;
      align-items: center;
      padding: 1rem 1.5rem;
      border-bottom: 1px solid rgba(255, 255, 255, 0.05);
      cursor: pointer;
      transition: background 0.2s;
    }

    .file-item:hover {
      background: rgba(255, 255, 255, 0.05);
    }

    .file-item:last-child {
      border-bottom: none;
    }

    .file-icon {
      font-size: 1.5rem;
      margin-right: 1rem;
      opacity: 0.7;
      flex-shrink: 0;
    }

    .file-info {
      flex: 1;
      min-width: 0;
    }

    .file-name {
      font-weight: 500;
      font-size: 1rem;
      margin-bottom: 0.25rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .file-path {
      font-size: 0.85rem;
      opacity: 0.7;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      margin-bottom: 0.25rem;
    }

    .file-meta {
      display: flex;
      gap: 1rem;
      font-size: 0.8rem;
      opacity: 0.6;
    }

    .file-score {
      font-size: 0.9rem;
      color: #4CAF50;
      margin-left: 1rem;
      flex-shrink: 0;
    }

    .loading {
      display: flex;
      align-items: center;
      justify-content: center;
      padding: 2rem;
      opacity: 0.7;
    }

    .empty-state {
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      padding: 3rem;
      opacity: 0.7;
      text-align: center;
    }

    .empty-state-icon {
      font-size: 3rem;
      margin-bottom: 1rem;
    }

    .empty-state-title {
      font-size: 1.2rem;
      margin-bottom: 0.5rem;
    }

    .empty-state-subtitle {
      font-size: 0.9rem;
      opacity: 0.7;
    }

    .search-stats {
      padding: 0.75rem 1.5rem;
      background: rgba(0, 0, 0, 0.2);
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      font-size: 0.9rem;
      opacity: 0.8;
    }
  `;

  constructor() {
    super();
    this.files = [];
    this.loading = false;
    this.query = '';
    this.searchResults = [];
    this.connected = false;
    this.sseHandler = null;
    this.searching = false;

    registerCommandHandler('kg_list_file', (data) => {
      console.log('........................................................................................')
      console.log({data})
      if (data.result.file) {
        this.searchResults.push(data.result.file);
      }
      this.loading = false;
      console.log(this.searchResults)
      return null;
    });

  }

  connectedCallback() {
    super.connectedCallback();
    this.setupSSE();
  }

  disconnectedCallback() {
    super.disconnectedCallback();
    if (this.sseHandler) {
      this.sseHandler.disconnect();
    }
  }

  async setupSSE() {
    const response = await fetch('/makesession/kg2')
    this.sessionId = await response.json().then(data => data.log_id);

    this.sseHandler = new SSEHandler(this.sessionId);
    
    this.sseHandler.on('connected', () => {
      this.connected = true;
      this.requestUpdate();
    });
    
    this.sseHandler.on('error', () => {
      this.connected = false;
      this.requestUpdate();
    });
    
    this.sseHandler.on('running_command', (data) => {
      console.log('running command')
      console.log({data})
      const val = Object.values(data.args)[0];
      this.lastCommand = data.command + ': ' + val;
      this.requestUpdate();
    })

    this.sseHandler.on('finished_chat', (data) => {
      console.log('finished chat')
      this.searching = false;
    })

    this.sseHandler.on('command_result', async (data) => {
      console.log('command result')
      console.log({data})
      await handleCommandEvent(data);
      this.requestUpdate();
    });
    
    this.sseHandler.connect();
  }

  async sendSearchMsg(userText) {
      console.log("sending search msg", userText)
      const request = new Request(`/chat/${this.sessionId}/send`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify([{type: "text", text: userText}])
      });
      this.searching = true;
      await fetch(request)
  }

  async handleFileClick(file) {
    try {
      console.log(`Opening file: ${file.path}`)
      const response = await fetch('/api/kg/open-file', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({ file_path: file.path })
      });
      
      const result = await response.json();
      
      if (result.success) {
        this.showMessage(`Opened file: ${file.name}`, 'success');
      } else {
        this.showMessage(`Failed to open file: ${result.error}`, 'error');
      }
    } catch (error) {
      console.error('Error opening file:', error);
      this.showMessage(`Error opening file: ${error.message}`, 'error');
    }
  }

  showMessage(message, type = 'info') {
    // Simple console logging for now - could be enhanced with notifications
    const color = type === 'success' ? '#4CAF50' : type === 'error' ? '#f44336' : '#2196F3';
    console.log(`%c${message}`, `color: ${color}`);
  }

  handleSearchInput(e) {
    const query = e.target.value.trim();
    
    // Debounce search
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      if (query.length > 2) {
        //this.loadFiles(query);
      } else if (query.length === 0) {
        //this.loadFiles();
      }
    }, 300);
  }

  handleSearchKeyDown(e) {
    console.log({e})
    if (e.key === 'Enter') {
      console.log("should send")
      e.preventDefault();
      const query = e.target.value.trim();
      console.log({query})
      if (query) {
        this.sendSearchMsg(query);
      }
    }
  }

  getFileIcon(filePath) {
    const ext = filePath.split('.').pop()?.toLowerCase();
    switch (ext) {
      case 'pdf': return '📄';
      case 'txt': case 'md': return '📝';
      case 'py': return '🐍';
      case 'js': return '📜';
      case 'html': return '🌐';
      case 'css': return '🎨';
      case 'json': return '📋';
      case 'xml': return '📰';
      case 'csv': return '📊';
      case 'doc': case 'docx': return '📄';
      case 'xls': case 'xlsx': return '📈';
      case 'ppt': case 'pptx': return '📊';
      case 'zip': case 'tar': case 'gz': return '📦';
      case 'jpg': case 'jpeg': case 'png': case 'gif': return '🖼️';
      case 'mp3': case 'wav': case 'ogg': return '🎵';
      case 'mp4': case 'avi': case 'mkv': return '🎬';
      default: return '📄';
    }
  }

  formatFileSize(bytes) {
    if (!bytes) return '';
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(1024));
    return Math.round(bytes / Math.pow(1024, i) * 100) / 100 + ' ' + sizes[i];
  }

  formatDate(dateString) {
    if (!dateString) return '';
    try {
      return new Date(dateString).toLocaleDateString();
    } catch {
      return dateString;
    }
  }

  _render() {
    return html`
      <div class="search-container">
        <div class="search-header">
          <h1 class="search-title">File Search</h1>
          <p class="search-subtitle">Search through your indexed files and documents</p>
          
          <div class="search-input-container">
            <input 
              type="text" 
              class="search-input" 
              placeholder="Search for files, content, or topics..."
              @input=${this.handleSearchInput}
              @keydown=${this.handleSearchKeyDown}
              .value=${this.query}
            >
          </div>
          
          <div class="connection-status ${this.connected ? 'connected' : 'disconnected'}">
            <span>${this.connected ? '✓' : '⚠'}</span>
            <span>${this.connected ? 'Connected' : 'Disconnected'}</span>
          </div>
        </div>

        <div class="search-status">
        ${this.searching ? html`<span class="spinner show"></span>` : ''}
        </div>

        <div class="status">
          ${this.lastCommand ? html `
            <it>${this.lastCommand}</it>
            ` : ''}
        </div>

        <div class="file-list-container">
          ${this.loading ? html`
            <div class="loading">
              <div>Loading files...</div>
            </div>
          ` : this.searchResults.length === 0 ? html`
            <div class="empty-state">
              <div class="empty-state-icon">📁</div>
              <div class="empty-state-title">
                ${this.query ? 'No files found' : 'No files indexed'}
              </div>
              <div class="empty-state-subtitle">
                ${this.query 
                  ? 'Try different search terms or check your spelling'
                  : 'Index some directories to see files here'}
              </div>
            </div>
          ` : html`
            ${this.searchResults.length > 0 ? html`
              <div class="search-stats">
                Found ${this.searchResults.length} file${this.searchResults.length === 1 ? '' : 's'}
                ${this.query ? ` for "${this.query}"` : ''}
              </div>
            ` : ''}
            
            <div class="file-list">
              ${this.searchResults.map(file => html`
                <div class="file-item" @click=${() => this.handleFileClick(file)}>
                  <span class="file-icon">${this.getFileIcon(file.path)}</span>
                  <div class="file-info">
                    <div class="file-path">${file.path}</div>
                    <div class="file-meta">
                      ${file.last_modified_str ? html`<span>Modified: ${file.last_modified_str}</span>` : ''}
                      ${file.size_str ? html`<span>Size: ${file.size_str}</span>` : ''}
                    </div>
                  </div>
                  ${file.score ? html`<div class="file-score">${(file.score * 100).toFixed(0)}%</div>` : ''}
                </div>
              `)}
            </div>
          `}
        </div>
      </div>
    `;
  }
}

customElements.define('kg-file-search', KgFileSearch);