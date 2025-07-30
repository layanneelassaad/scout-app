# Scout App

product description

## Prerequisites

- **macOS** (required for Swift development) **arm?
- **Xcode** (for building the Swift app)
- **Python 3.9+** (for the backend)

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