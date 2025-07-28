import { LitElement, html, css } from '/admin/static/js/lit-core.min.js';
import { BaseEl } from '/admin/static/js/base.js';

class KnowledgeGraphAdmin extends BaseEl {
  static properties = {
    watchedDirs: { type: Array },
    stats: { type: Object },
    loading: { type: Boolean },
    newDirPath: { type: String },
    newDirSchedule: { type: String },
  };

  static styles = css`
    :host {
      display: block;
      padding: 1rem;
      background-color: var(--background-color, #1a1a1a);
      color: var(--text-color, #fff);
    }
    .kg-admin-container {
      display: flex;
      flex-direction: column;
      gap: 1.5rem;
    }
    .section {
      background: rgba(0,0,0,0.2);
      border: 1px solid rgba(255,255,255,0.1);
      border-radius: 8px;
      padding: 1rem;
    }
    h2 {
      margin-top: 0;
      border-bottom: 1px solid rgba(255,255,255,0.2);
      padding-bottom: 0.5rem;
    }
    .stats-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
      gap: 1rem;
      text-align: center;
    }
    .stat-item h3 {
      margin: 0 0 0.5rem 0;
      font-size: 1.5rem;
      color: #4a90e2;
    }
    .stat-item p {
      margin: 0;
      font-size: 0.9rem;
      color: #aaa;
    }
    .add-dir-form {
      display: flex;
      gap: 1rem;
      align-items: center;
      flex-wrap: wrap;
    }
    input[type='text'], select {
      padding: 0.5rem;
      border-radius: 4px;
      border: 1px solid #444;
      background: #222;
      color: #fff;
      flex-grow: 1;
    }
    button {
      padding: 0.5rem 1rem;
      border-radius: 4px;
      border: none;
      background: #4a90e2;
      color: #fff;
      cursor: pointer;
      transition: background 0.2s;
    }
    button:hover {
      background: #357abd;
    }
    button.danger {
      background: #e24a4a;
    }
    button.danger:hover {
      background: #bd3535;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin-top: 1rem;
    }
    th, td {
      padding: 0.75rem;
      text-align: left;
      border-bottom: 1px solid #333;
    }
    th {
      background: rgba(0,0,0,0.3);
    }
    .actions button {
      margin-right: 0.5rem;
    }
    .status-active { color: #4caf50; }
    .status-error { color: #f44336; }
  `;

  constructor() {
    super();
    this.watchedDirs = [];
    this.stats = {};
    this.loading = true;
    this.newDirPath = '';
    this.newDirSchedule = 'hourly';
  }

  connectedCallback() {
    super.connectedCallback();
    this.fetchData();
  }

  async fetchData() {
    this.loading = true;
    await Promise.all([
      this.fetchWatchedDirs(),
      this.fetchStats(),
    ]);
    this.loading = false;
  }

  async fetchWatchedDirs() {
    try {
      const response = await fetch('/api/kg/watched-dirs');
      const result = await response.json();
      if (result.success) {
        this.watchedDirs = result.data;
      } else {
        console.error('Error fetching watched dirs:', result.error);
      }
    } catch (e) {
      console.error('Error fetching watched dirs:', e);
    }
  }

  async fetchStats() {
    try {
      const response = await fetch('/api/kg/stats');
      const result = await response.json();
      if (result.success) {
        this.stats = result.data;
      } else {
        console.error('Error fetching stats:', result.error);
      }
    } catch (e) {
      console.error('Error fetching stats:', e);
    }
  }

  async handleAddDirectory() {
    if (!this.newDirPath) return;
    try {
      const response = await fetch('/api/kg/add-watched-dir', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path: this.newDirPath, schedule: this.newDirSchedule }),
      });
      const result = await response.json();
      if (result.success) {
        this.newDirPath = '';
        this.fetchWatchedDirs();
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (e) {
      console.error('Error adding directory:', e);
    }
  }

  async handleRemoveDirectory(path) {
    if (!confirm(`Are you sure you want to remove ${path}?`)) return;
    try {
      const response = await fetch('/api/kg/remove-watched-dir', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path }),
      });
      const result = await response.json();
      if (result.success) {
        this.fetchWatchedDirs();
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (e) {
      console.error('Error removing directory:', e);
    }
  }

  async handleIndexDirectory(path) {
    this.loading = true;
    try {
      const response = await fetch('/api/kg/index-directory', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ path }),
      });
      const result = await response.json();
      if (result.success) {
        alert(`Indexing complete for ${path}. Processed: ${result.files_processed}, Errors: ${result.total_errors}`);
        this.fetchData();
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (e) {
      console.error('Error indexing directory:', e);
    } finally {
      this.loading = false;
    }
  }

  async handleRunScheduler() {
    this.loading = true;
    try {
      const response = await fetch('/api/kg/run-scheduled', { method: 'POST' });
      const result = await response.json();
      if (result.success) {
        alert(`Scheduler run complete. Processed: ${result.processed.length}, Errors: ${result.errors.length}`);
        this.fetchData();
      } else {
        alert(`Error: ${result.error}`);
      }
    } catch (e) {
      console.error('Error running scheduler:', e);
    } finally {
      this.loading = false;
    }
  }

  render() {
    if (this.loading) {
      return html`<p>Loading...</p>`;
    }

    return html`
      <div class="kg-admin-container">
        <div class="section stats-section">
          <h2>Knowledge Graph Overview</h2>
          <div class="stats-grid">
            <div class="stat-item">
              <h3>${this.stats.total_entities || 0}</h3>
              <p>Total Entities</p>
            </div>
            <div class="stat-item">
              <h3>${this.stats.total_relationships || 0}</h3>
              <p>Total Relationships</p>
            </div>
            <div class="stat-item">
              <h3>${this.watchedDirs.length}</h3>
              <p>Watched Directories</p>
            </div>
          </div>
        </div>

        <div class="section watched-dirs-section">
          <h2>Watched Directories</h2>
          <div class="add-dir-form">
            <input 
              type="text" 
              placeholder="/path/to/directory"
              .value=${this.newDirPath}
              @input=${e => this.newDirPath = e.target.value}
            />
            <select .value=${this.newDirSchedule} @change=${e => this.newDirSchedule = e.target.value}>
              <option value="manual">Manual</option>
              <option value="hourly">Hourly</option>
              <option value="daily">Daily</option>
              <option value="weekly">Weekly</option>
            </select>
            <button @click=${this.handleAddDirectory}>Add Directory</button>
            <button @click=${this.handleRunScheduler}>Run Scheduled Indexing</button>
          </div>
          <table>
            <thead>
              <tr>
                <th>Path</th>
                <th>Schedule</th>
                <th>Status</th>
                <th>File Count</th>
                <th>Last Indexed</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              ${this.watchedDirs.map(dir => html`
                <tr>
                  <td>${dir.path}</td>
                  <td>${dir.schedule}</td>
                  <td><span class="status-${dir.status.toLowerCase()}">${dir.status}</span></td>
                  <td>${dir.file_count}</td>
                  <td>${dir.last_indexed ? new Date(dir.last_indexed).toLocaleString() : 'Never'}</td>
                  <td class="actions">
                    <button @click=${() => this.handleIndexDirectory(dir.path)}>Index Now</button>
                    <button class="danger" @click=${() => this.handleRemoveDirectory(dir.path)}>Remove</button>
                  </td>
                </tr>
              `)}
            </tbody>
          </table>
        </div>
      </div>
    `;
  }
}

customElements.define('kg-admin', KnowledgeGraphAdmin);