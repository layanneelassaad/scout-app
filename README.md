# Scout App
> **Scout** is a local platform to **install, run, and manage AI agents** on your Mac. It ships with a curated set of useful starter agents, an **Agent Store** for discovery, a centralized **Agent Manager** for permissions, and a **Knowledge Graph** that helps agents reason over the files you explicitly allow.


## Product description

- **Agent Store.** Browse agents like an App Store: each agent has a page with a description, reviews, and the **exact permissions** it requests (e.g., file access to selected folders, network, calendar).  
- **Agent Manager.** A single pane to **view installed agents**, enable/disable them, and **grant/revoke permissions** at any time. Every capability is **opt-in** and explicit.  
- **Permissioned Search Agent (example).** Before use, you grant the Search Agent read access to specific folders only. It will **not** see anything else.  
- **Knowledge Graph (optional).** If enabled, Scout builds a local, fast index/graph over the user-selected files. Agents can use the graph to improve retrieval and reasoning. You choose the scope (e.g., a single folder for quick indexing).  
- **Local-first & secure.** Agents run locally; nothing is indexed or shared unless you opt in. Integrations with external services are permission-gated and transparent.

## Prerequisites

- **macOS 13+**  
  - **Apple Silicon (arm64)** recommended. (The default build targets `arm64`; for Intel, see notes below.)
- **Xcode 15+** (includes Command Line Tools)
- **Python 3.9+** (for embedded/backend services)
- **Node 18+** (only for optional Stripe test server)
- **Stripe CLI** (optional; for payments demo)
- > **Intel build:** set `ARCH=x86_64` when invoking the build script, or adjust your Xcode scheme to produce an x86_64 binary. For a universal build, compile both and lipo them (advanced).


## Building the Application

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   ```

2. **Navigate to the SwiftApp directory:**
   ```bash
   cd scout-app/SwiftApp
   ```

3. **Run the build script:**
   ```bash
   ./build_mac_app_scout.sh
   ```

### Build Process Details

The build script performs the following steps:

1. **Swift App Build**: Compiles the Swift application using Xcode
2. **Python Environment**: Creates a virtual environment with all dependencies
3. **Backend Integration**: Copies the Python backend into the app bundle
4. **Launcher Scripts**: Creates startup scripts for the integrated app
5. **App Bundle**: Produces a complete `Scout.app` bundle

### Alternative Build Options

- **Fixed Build Script**: `./build_scout_fixed.sh` (preserves app signing) **TODO ADDRESS
- **DMG Creation**: `./create_dmg_scout.sh` (creates distribution package)

### Test Stripe Payment

1. Copy your real keys into backend/.env (from .env.example).
2. Run stripe backend
```bash
cd backend
stripe listen \
  --forward-to localhost:4242/webhook \
  --events checkout.session.completed
```


3. Run app backend
```bash
   cd backend
   npm start
```

## Testing the Application

### Run the Built App
Either double click the app or run
```bash
./scout_app_build/Scout.app/Contents/Resources/launch_scout.sh
```

### Test Backend Connection
```bash
python test_connection.py
```

### Test Search Functionality
```bash
python test_search.py
```
