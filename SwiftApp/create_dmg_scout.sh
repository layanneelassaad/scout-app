#!/bin/bash

# Script to create a DMG file for Scout app distribution
# Run this after building the app bundle with build_mac_app_scout.sh
# Updated for Scout branding and git repository paths

set -e

APP_NAME="Scout"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BUILD_DIR="$SCRIPT_DIR/scout_app_build"
APP_BUNDLE="$BUILD_DIR/filesearch.app"  # App bundle name (kept as filesearch.app for signing)
DMG_NAME="$APP_NAME-v1.0"
DMG_PATH="$BUILD_DIR/$DMG_NAME.dmg"

echo "========================================"
echo "Creating DMG for $APP_NAME"
echo "========================================"

# Check if app bundle exists
if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: App bundle not found at $APP_BUNDLE"
    echo "Please run build_mac_app_scout.sh first to create the app bundle"
    exit 1
fi

# Remove any existing DMG
rm -f "$DMG_PATH"

# Create temporary DMG directory
TEMP_DMG_DIR="$BUILD_DIR/dmg_temp"
rm -rf "$TEMP_DMG_DIR"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to temp directory
cp -r "$APP_BUNDLE" "$TEMP_DMG_DIR/"

# Create symlink to Applications folder for easy installation
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Create a README for the DMG
cat > "$TEMP_DMG_DIR/README.txt" << 'EOF'
Scout Application
================

Installation:
1. Drag "filesearch.app" to the Applications folder
2. Double-click to run Scout

Important Notes:
- This app includes an embedded Python backend
- On first run, macOS may show security warnings
- Go to System Preferences > Security & Privacy to allow the app to run
- The app will start its backend automatically
- No additional setup required

About the app name:
- The file is named "filesearch.app" to preserve macOS code signing
- The application displays as "Scout" when running
- This is normal and does not affect functionality

Troubleshooting:
- If the app won't open, check System Preferences > Security & Privacy
- Try right-clicking the app and selecting "Open" for first run
- Check Console.app for any error messages

For support, contact your development team.
EOF

echo "Creating DMG file..."
hdiutil create -volname "$APP_NAME Installer" \
                -srcfolder "$TEMP_DMG_DIR" \
                -ov -format UDZO \
                "$DMG_PATH"

# Clean up temp directory
rm -rf "$TEMP_DMG_DIR"

echo "========================================"
echo "DMG created successfully!"
echo "========================================"
echo "DMG file: $DMG_PATH"
echo "File size: $(du -h "$DMG_PATH" | cut -f1)"
echo ""
echo "Distribution ready!"
echo "Users can:"
echo "1. Download and mount this DMG file"
echo "2. Drag the app to Applications folder"
echo "3. Double-click to run Scout"
echo ""
echo "The DMG contains:"
echo "- filesearch.app (the Scout application)"
echo "- Applications folder shortcut"
echo "- README.txt with installation instructions"
echo "========================================"