#!/bin/bash

# Build script for macOS app bundle with embedded Python backend
# This creates a complete Scout.app bundle that can be distributed
# Updated for Scout branding and git repository paths

set -e  # Exit on any error

echo "========================================"
echo "Building Scout.app with embedded backend"
echo "========================================"

# Configuration
APP_NAME="Scout"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SWIFT_PROJECT_DIR="."
PYTHON_BACKEND_DIR="$SCRIPT_DIR/../kg"  # Fix: Point to actual kg directory
BUILD_DIR="$SCRIPT_DIR/scout_app_build"
APP_BUNDLE="$BUILD_DIR/Scout.app"  # Use Scout.app name
BACKEND_PORT=8020  # Match what Swift app expects

# Clean previous build
echo "Cleaning previous build..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Install Node/Stripe dependencies
echo "Installing backend (Stripe) dependencies..."
pushd "$SCRIPT_DIR/../backend" >/dev/null
  npm ci
popd >/dev/null

# Build Swift app
echo "Building Swift application..."
cd "$SWIFT_PROJECT_DIR/Scout"
xcodebuild -project Scout.xcodeproj -scheme Scout -configuration Release build

# Find and copy the built app
echo "Looking for built Swift app..."
BUILT_APP=$(find "$SWIFT_PROJECT_DIR/Scout" -name "Scout.app" -path "*/Build/Products/Release/*" 2>/dev/null | head -1)

# If not found in project directory, check DerivedData
if [ -z "$BUILT_APP" ]; then
    echo "Not found in project directory, checking DerivedData..."
    BUILT_APP=$(find ~/Library/Developer/Xcode/DerivedData -name "Scout.app" -path "*/Build/Products/Release/*" 2>/dev/null | head -1)
fi

if [ -z "$BUILT_APP" ]; then
    echo "Error: Could not find built Swift app"
    exit 1
fi

echo "Found Swift app at: $BUILT_APP"
cp -r "$BUILT_APP" "$BUILD_DIR/"
echo "Swift app copied successfully"

# Create Python environment
echo "Creating Python environment..."
cd "$PYTHON_BACKEND_DIR"

# Create a clean virtual environment for distribution
PYTHON_ENV_DIR="$APP_BUNDLE/Contents/Resources/python-env"
mkdir -p "$APP_BUNDLE/Contents/Resources"

# Use Python 3.9+ as required by the backend
python3 -m venv "$PYTHON_ENV_DIR"
source "$PYTHON_ENV_DIR/bin/activate"

# Upgrade pip
pip install --upgrade pip setuptools wheel

# Install the backend package and all dependencies
echo "Installing backend dependencies (this may take several minutes)..."
pip install -r "$PYTHON_BACKEND_DIR/requirements.txt"

# Copy backend source code
echo "Copying backend source..."
BACKEND_DIR="$APP_BUNDLE/Contents/Resources/backend"
mkdir -p "$BACKEND_DIR"



# Copy the entire kg directory structure
cp -r "$PYTHON_BACKEND_DIR"/* "$BACKEND_DIR/"
echo "Copied entire kg backend directory"

# Create a kg symlink so uvicorn can find the module
cd "$APP_BUNDLE/Contents/Resources"
ln -sf backend kg
echo "Created kg symlink for uvicorn"

# Copy .env file (important for backend configuration)
if [ -f "$PYTHON_BACKEND_DIR/.env" ]; then
    cp "$PYTHON_BACKEND_DIR/.env" "$BACKEND_DIR/"
    echo "Copied .env file"
else
    echo "Warning: No .env file found in backend directory"
fi

# Copy data directories
if [ -d "$PYTHON_BACKEND_DIR/personas" ]; then
    cp -r "$PYTHON_BACKEND_DIR/personas" "$BACKEND_DIR/"
    echo "Copied personas directory"
else
    mkdir -p "$BACKEND_DIR/personas"
    echo "Created empty personas directory"
fi

if [ -d "$PYTHON_BACKEND_DIR/models" ]; then
    cp -r "$PYTHON_BACKEND_DIR/models" "$BACKEND_DIR/"
    echo "Copied models directory"
else
    mkdir -p "$BACKEND_DIR/models"
    echo "Created empty models directory"
fi

if [ -d "$PYTHON_BACKEND_DIR/data" ]; then
    cp -r "$PYTHON_BACKEND_DIR/data" "$BACKEND_DIR/"
    echo "Copied data directory"
else
    mkdir -p "$BACKEND_DIR/data"
    echo "Created empty data directory"
fi

# Create other required directories
mkdir -p "$BACKEND_DIR/imgs"
mkdir -p "$BACKEND_DIR/logs"
echo "Created imgs and logs directories"

deactivate

echo "Creating backend launcher script..."
cat > "$APP_BUNDLE/Contents/Resources/start_backend.sh" << 'EOF'
#!/bin/bash

# Get the directory where this script is located
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
APP_RESOURCES="$SCRIPT_DIR"
BACKEND_DIR="$APP_RESOURCES/backend"
PYTHON_ENV="$APP_RESOURCES/python-env"

# Change to backend directory
cd "$BACKEND_DIR"

# Activate Python environment
source "$PYTHON_ENV/bin/activate"

# Set Python path to include backend directory
export PYTHONPATH="$BACKEND_DIR:$PYTHONPATH"

echo "Starting Scout backend on port 8020..."
echo "Working directory: $(pwd)"
echo "Data directory: $(pwd)/data"
echo "Personas directory: $(pwd)/personas"

# Start the backend server on port 8020 using the virtual environment's uvicorn
cd "$BACKEND_DIR/.."
"$PYTHON_ENV/bin/uvicorn" kg:app --host 0.0.0.0 --port 8020
EOF

chmod +x "$APP_BUNDLE/Contents/Resources/start_backend.sh"

echo "Creating app startup wrapper..."
# Create a launcher script in Resources instead of replacing the executable
cat > "$APP_BUNDLE/Contents/Resources/launch_scout.sh" << 'EOF'
#!/bin/bash

# Get the app bundle path
APP_BUNDLE="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." && pwd )"
RESOURCES="$APP_BUNDLE/Resources"
EXECUTABLE="$APP_BUNDLE/MacOS/Scout"

# Function to check if backend is running
check_backend() {
    curl -s http://localhost:8020 >/dev/null 2>&1
}

# Start backend in background if not already running
if ! check_backend; then
    echo "Starting Scout backend..."
    "$RESOURCES/start_backend.sh" &
    BACKEND_PID=$!
    
    # Wait for backend to start (max 30 seconds)
    for i in {1..30}; do
        if check_backend; then
            echo "Scout backend started successfully"
            break
        fi
        if [ $i -eq 30 ]; then
            echo "Warning: Backend may not have started properly"
            # Continue anyway, maybe it's already running
        fi
        sleep 1
    done
fi

# Start the Swift app
exec "$EXECUTABLE" "$@"
EOF

chmod +x "$APP_BUNDLE/Contents/Resources/launch_scout.sh"

echo "========================================"
echo "Scout app bundle build completed!"
echo "========================================"
echo "App bundle created at: $APP_BUNDLE"
echo "This is a complete Scout.app with embedded backend."
echo ""
echo "TO TEST:"
echo "  '$APP_BUNDLE/Contents/Resources/launch_scout.sh'"
echo "  This will start the backend and then launch Scout"
echo "  Or double-click the app bundle to run normally"
echo ""
echo "TO DISTRIBUTE:"
echo "  1. Test the app bundle works"
echo "  2. Create a DMG: ./create_dmg_scout.sh"
echo "  3. Or zip the .app bundle directly"
echo ""
echo "NOTES:"
echo "- App bundle is ~200-400MB due to embedded Python environment"
echo "- Backend starts automatically when app opens"
echo "- App file is still named 'filesearch.app' to preserve signing"
echo "- Application displays as 'Scout' when running"
echo "========================================"