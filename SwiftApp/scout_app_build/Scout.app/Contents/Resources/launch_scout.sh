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
