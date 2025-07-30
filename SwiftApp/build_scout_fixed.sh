#!/bin/bash

# Scout App Build Script - Fixed version that doesn't rename the app bundle
# Renaming breaks macOS app signing/validation

set -e

echo "========================================"
echo "Scout Application Build (Fixed)"
echo "========================================"

APP_NAME="Scout"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWIFT_PROJECT_DIR="."
PYTHON_BACKEND_DIR="/Users/administrator/agentcore"
BUILD_DIR="$SCRIPT_DIR/scout_build"
PACKAGE_DIR="$BUILD_DIR/$APP_NAME-Package"

# Clean and create build directory
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$PACKAGE_DIR"

# Build Swift app
echo "Building Swift app..."
cd "$SWIFT_PROJECT_DIR"
# xcodebuild -project filesearch.xcodeproj -scheme filesearch -configuration Release build

# Find and copy the built app - check both project dir and DerivedData
echo "Looking for built Swift app..."
BUILT_APP=$(find "$SWIFT_PROJECT_DIR" -name "filesearch.app" -path "*/Build/Products/Release/*" 2>/dev/null | head -1)

# If not found in project directory, check DerivedData
if [ -z "$BUILT_APP" ]; then
    echo "Not found in project directory, checking DerivedData..."
    BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "filesearch.app" -path "*/Build/Products/Release/*" 2>/dev/null | head -1)
fi

if [ -z "$BUILT_APP" ]; then
    echo "Error: Could not find built Swift app in either location"
    echo "Searched in: $SWIFT_PROJECT_DIR and ~/Library/Developer/Xcode/DerivedData"
    exit 1
fi

echo "Found Swift app at: $BUILT_APP"
# Copy the app WITHOUT renaming to preserve app bundle integrity
cp -r "$BUILT_APP" "$PACKAGE_DIR/"
echo "Swift app copied as filesearch.app (keeping original name to preserve signing)"

# Create Python backend package
echo "Creating Python backend..."
BACKEND_PKG="$PACKAGE_DIR/Backend"
mkdir -p "$BACKEND_PKG"

# Create virtual environment
echo "Setting up Python environment..."
cd "$PYTHON_BACKEND_DIR"
python3 -m venv "$BACKEND_PKG/venv"
source "$BACKEND_PKG/venv/bin/activate"
pip install --upgrade pip
echo "Installing backend dependencies (this may take a few minutes)..."
pip install -e "$PYTHON_BACKEND_DIR"
deactivate

# Copy backend source files
echo "Copying backend source files..."
cp -r "$PYTHON_BACKEND_DIR/src" "$BACKEND_PKG/"
cp "$PYTHON_BACKEND_DIR/pyproject.toml" "$BACKEND_PKG/"

# Copy configuration files
echo "Copying configuration files..."
cp -r "$PYTHON_BACKEND_DIR/config" "$BACKEND_PKG/" 2>/dev/null || echo "No config directory found"
cp -r "$PYTHON_BACKEND_DIR/static" "$BACKEND_PKG/" 2>/dev/null || echo "No static directory found"

# Copy .env file (important for backend configuration)
if [ -f "$PYTHON_BACKEND_DIR/.env" ]; then
    cp "$PYTHON_BACKEND_DIR/.env" "$BACKEND_PKG/"
    echo "Copied .env file"
else
    echo "Warning: No .env file found in backend directory"
fi

# Copy data directories (backend expects these relative to its working directory)
echo "Copying data directories..."
if [ -d "$PYTHON_BACKEND_DIR/data" ]; then
    cp -r "$PYTHON_BACKEND_DIR/data" "$BACKEND_PKG/"
    echo "Copied data directory"
else
    mkdir -p "$BACKEND_PKG/data"
    echo "Created empty data directory"
fi

if [ -d "$PYTHON_BACKEND_DIR/personas" ]; then
    cp -r "$PYTHON_BACKEND_DIR/personas" "$BACKEND_PKG/"
    echo "Copied personas directory"
else
    mkdir -p "$BACKEND_PKG/personas"
    echo "Created empty personas directory"
fi

if [ -d "$PYTHON_BACKEND_DIR/models" ]; then
    cp -r "$PYTHON_BACKEND_DIR/models" "$BACKEND_PKG/"
    echo "Copied models directory"
else
    mkdir -p "$BACKEND_PKG/models"
    echo "Created empty models directory"
fi

# Create other required directories
mkdir -p "$BACKEND_PKG/imgs"
mkdir -p "$BACKEND_PKG/logs"
echo "Created imgs and logs directories"

# Create startup scripts
echo "Creating startup scripts..."

# Backend startup script (runs from Backend directory so data paths are relative)
cat > "$BACKEND_PKG/start_backend.sh" << 'EOF'
#!/bin/bash
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

# Activate Python environment
source venv/bin/activate

# Set Python path to include backend source
export PYTHONPATH="$SCRIPT_DIR/src:$PYTHONPATH"

echo "Starting Scout backend on port 8020..."
echo "Working directory: $(pwd)"
echo "Data directory: $(pwd)/data"
echo "Personas directory: $(pwd)/personas"

# Start the backend server on port 8020
python -m agentcore.server --port 8020
EOF
chmod +x "$BACKEND_PKG/start_backend.sh"

# Main startup script
cat > "$PACKAGE_DIR/Start Scout.command" << 'EOF'
#!/bin/bash
# Get directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$SCRIPT_DIR"

echo "========================================"
echo "Starting Scout Application"
echo "========================================"
echo "1. Starting backend server..."
"./Backend/start_backend.sh" &
BACKEND_PID=$!

# Function to check if backend is responding
check_backend() {
    curl -s http://localhost:8020 >/dev/null 2>&1
}

# Wait for backend to start (max 30 seconds)
echo "Waiting for backend to start..."
for i in {1..30}; do
    if check_backend; then
        echo "Backend is ready!"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "Warning: Backend may not have started properly"
        echo "Check the terminal window for error messages"
    fi
    sleep 1
done

echo "2. Starting Scout app..."
# Open the app with its original name to avoid signing issues
open "filesearch.app"

echo "========================================"
echo "Scout is starting!"
echo "Backend PID: $BACKEND_PID"
echo "To stop the backend: kill $BACKEND_PID"
echo "Or use 'Stop Scout Backend.command'"
echo "========================================"
EOF
chmod +x "$PACKAGE_DIR/Start Scout.command"

# Create stop script
cat > "$PACKAGE_DIR/Stop Scout Backend.command" << 'EOF'
#!/bin/bash
echo "Stopping Scout backend..."
pkill -f "agentcore.server" && echo "Backend stopped successfully" || echo "Backend was not running"
EOF
chmod +x "$PACKAGE_DIR/Stop Scout Backend.command"

# Create comprehensive README
cat > "$PACKAGE_DIR/README.txt" << 'EOF'
Scout Application Package
========================

This package contains:
- filesearch.app (Scout frontend - kept original name to preserve app signing)
- Backend/ (Python backend with all dependencies and data)
- Start Scout.command (launches both backend and frontend)
- Stop Scout Backend.command (stops the backend server)

IMPORTANT: The app file is still named "filesearch.app" to preserve 
macOS code signing. The application itself displays as "Scout" when running.

INSTALLATION & USAGE:
1. Double-click "Start Scout.command"
2. Wait for "Backend is ready!" message
3. Scout app will open automatically

DISTRIBUTION:
1. Zip this entire folder
2. Recipients can unzip and run "Start Scout.command"

IMPORTANT NOTES:
- Backend runs on port 8020
- All data (personas, models, etc.) is included in Backend/
- macOS may show security warnings on first run
- Go to System Preferences > Security & Privacy to allow the app

DATA DIRECTORIES:
The backend includes its own copies of:
- data/ (application data)
- personas/ (AI personas)
- models/ (ML models)
- config/ (configuration files)

This means the packaged app is completely independent from 
the development environment.

TROUBLESHOoting:
- If Scout can't connect: ensure backend started successfully
- Check Console.app for error messages
- Try "Stop Scout Backend.command" then restart
- Backend terminal window shows detailed logs

SUPPORT:
For technical support, contact your development team.
EOF

echo "========================================"
echo "Scout build completed successfully!"
echo "========================================"
echo "Package created at: $PACKAGE_DIR"
echo "App kept as: filesearch.app (to preserve macOS signing)"
echo "Backend includes independent data directories"
echo ""
echo "TO TEST:"
echo "  cd '$PACKAGE_DIR'"
echo "  ./\"Start Scout.command\""
echo ""
echo "TO DISTRIBUTE:"
echo "  cd '$BUILD_DIR'"
echo "  zip -r 'Scout-Package.zip' '$APP_NAME-Package/'"
echo "========================================"