import { LitElement, html, css } from '/chat/static/js/lit-core.min.js';
import { BaseEl } from '/chat/static/js/base.js';
import { registerCommandHandler } from './command-handler.js';

class KgFileList extends BaseEl {
  static properties = {
    files: { type: Array },
    loading: { type: Boolean },
    query: { type: String },
    expanded: { type: Boolean },
    limit: { type: Number }
  };

  static styles = css`
    :host {
      display: block;
      width: 100%;
      background: var(--component-bg, var(--background-color));
      color: var(--component-text, var(--text-color));
    }

    .file-list-header {
      display: flex;
      align-items: center;
      justify-content: space-between;
      padding: 0.5rem 1rem;
      background: rgba(0, 0, 0, 0.2);
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
      cursor: pointer;
      user-select: none;
    }

    .file-list-header:hover {
      background: rgba(0, 0, 0, 0.3);
    }

    .header-title {
      display: flex;
      align-items: center;
      gap: 0.5rem;
      font-weight: 500;
    }

    .expand-icon {
      transition: transform 0.2s;
    }

    .expand-icon.expanded {
      transform: rotate(90deg);
    }

    .file-count {
      background: rgba(255, 255, 255, 0.1);
      padding: 0.2rem 0.5rem;
      border-radius: 12px;
      font-size: 0.8rem;
    }

    .file-list-content {
      max-height: 0;
      overflow: hidden;
      transition: max-height 0.3s ease;
    }

    .file-list-content.expanded {
      max-height: 300px;
    }

    .search-container {
      padding: 0.5rem 1rem;
      border-bottom: 1px solid rgba(255, 255, 255, 0.1);
    }

    .search-input {
      width: 100%;
      padding: 0.5rem;
      background: rgba(0, 0, 0, 0.2);
      border: 1px solid rgba(255, 255, 255, 0.1);
      border-radius: 4px;
      color: var(--text-color);
      font-size: 0.9rem;
    }

    .search-input:focus {
      outline: none;
      border-color: rgba(255, 255, 255, 0.3);
    }

    .file-list {
      max-height: 200px;
      overflow-y: auto;
    }

    .file-item {
      display: flex;
      align-items: center;
      padding: 0.5rem 1rem;
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
      margin-right: 0.5rem;
      opacity: 0.7;
      font-size: 1.2rem;
    }

    .file-info {
      flex: 1;
      min-width: 0;
    }

    .file-name {
      font-weight: 500;
      margin-bottom: 0.2rem;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
      font-size: 0.9rem;
    }

    .file-path {
      font-size: 0.75rem;
      opacity: 0.7;
      white-space: nowrap;
      overflow: hidden;
      text-overflow: ellipsis;
    }

    .file-score {
      font-size: 0.8rem;
      color: #4CAF50;
      margin-left: 0.5rem;
      flex-shrink: 0;
    }

    .loading {
      padding: 1rem;
      text-align: center;
      opacity: 0.7;
      font-size: 0.9rem;
    }

    .empty-state {
      padding: 1rem;
      text-align: center;
      opacity: 0.7;
      font-style: italic;
      font-size: 0.9rem;
    }

    .error-state {
      padding: 1rem;
      text-align: center;
      color: #f44336;
      font-size: 0.9rem;
    }
  `;

  constructor() {
    super();
    this.files = [];
    this.loading = false;
    this.query = '';
    this.expanded = false;
    this.limit = 10;
    
    // Load initial files
    this.loadFiles();
  }

  async loadFiles(query = null) {
    this.loading = true;
    this.query = query || '';
    
    try {
      const requestBody = {
        query: query,
        limit: this.limit,
        semantic: true,
        threshold: 0.6
      };
      
      const response = await fetch('/mr_kg/api/kg/list-files', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${window.access_token}`
        },
        body: JSON.stringify(requestBody)
      });
      
      if (response.ok) {
        const result = await response.json();
        if (result.success) {
          this.files = result.data.files || [];
          if (this.files.length > 0 && !this.expanded) {
            this.expanded = true;
          }
        } else {
          console.error('Failed to load files:', result.error);
          this.files = [];
        }
      } else {
        console.error('HTTP error:', response.status);
        this.files = [];
      }
    } catch (error) {
      console.error('Error loading files:', error);
      this.files = [];
    } finally {
      this.loading = false;
      this.requestUpdate();
    }
  }

  async searchFiles(query) {
    if (query !== this.query) {
      await this.loadFiles(query);
    }
  }

  async handleFileClick(file) {
    try {
      const response = await fetch('/mr_kg/api/kg/open-file', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${window.access_token}`
        },
        body: JSON.stringify({ file_path: file.path })
      });
      
      const result = await response.json();
      
      if (result.success) {
        this.showMessage(`✓ Opened file: ${file.name}`, 'success');
      } else {
        this.showMessage(`Failed to open file: ${result.error}`, 'error');
      }
    } catch (error) {
      console.error('Error opening file:', error);
      this.showMessage(`Error opening file: ${error.message}`, 'error');
    }
  }

  showMessage(message, type = 'info') {
    // Simple console logging - could be enhanced with notifications
    const color = type === 'success' ? '#4CAF50' : type === 'error' ? '#f44336' : '#2196F3';
    console.log(`%c${message}`, `color: ${color}`);
  }

  toggleExpanded() {
    this.expanded = !this.expanded;
  }

  handleSearchInput(e) {
    const query = e.target.value.trim();
    
    // Debounce search
    clearTimeout(this.searchTimeout);
    this.searchTimeout = setTimeout(() => {
      if (query.length > 2) {
        this.searchFiles(query);
      } else if (query.length === 0) {
        this.loadFiles();
      }
    }, 300);
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
      default: return '📄';
    }
  }

  _render() {
    return html`
      <div class="file-list-header" @click=${this.toggleExpanded}>
        <div class="header-title">
          <span class="expand-icon ${this.expanded ? 'expanded' : ''}">▶</span>
          <span>Relevant Files</span>
          ${this.files.length > 0 ? html`<span class="file-count">${this.files.length}</span>` : ''}
        </div>
      </div>
      
      <div class="file-list-content ${this.expanded ? 'expanded' : ''}">
        <div class="search-container">
          <input 
            type="text" 
            class="search-input" 
            placeholder="Search files..."
            @input=${this.handleSearchInput}
            .value=${this.query}
          >
        </div>
        
        <div class="file-list">
          ${this.loading ? html`
            <div class="loading">Loading files...</div>
          ` : this.files.length === 0 ? html`
            <div class="empty-state">
              ${this.query ? 'No files found for your search.' : 'No files indexed yet.'}
            </div>
          ` : this.files.map(file => html`
            <div class="file-item" @click=${() => this.handleFileClick(file)}>
              <span class="file-icon">${this.getFileIcon(file.path)}</span>
              <div class="file-info">
                <div class="file-name">${file.name}</div>
                <div class="file-path">${file.path}</div>
              </div>
              ${file.score ? html`<div class="file-score">${(file.score * 100).toFixed(0)}%</div>` : ''}
            </div>
          `)}
        </div>
      </div>
    `;
  }
}

// Register command handlers for backward compatibility
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

customElements.define('kg-file-list', KgFileList);