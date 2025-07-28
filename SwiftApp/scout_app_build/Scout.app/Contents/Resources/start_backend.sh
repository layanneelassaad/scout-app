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

# Start the backend server on port 8020
uvicorn main:app --host 0.0.0.0 --port 8020
