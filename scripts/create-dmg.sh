#!/bin/bash

# DesignDiff DMG Creation Script
# This script builds the app and creates a DMG for distribution

set -e

# Configuration
APP_NAME="DesignDiff"
VERSION="1.0.0"
BUILD_DIR="build"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
VOLUME_NAME="${APP_NAME} ${VERSION}"

echo "🚀 Building ${APP_NAME}..."

# Clean previous builds
rm -rf "${BUILD_DIR}"
mkdir -p "${BUILD_DIR}"

# Build the app (Release configuration)
cd DesignDiff
xcodebuild -scheme DesignDiff \
    -configuration Release \
    -derivedDataPath "../${BUILD_DIR}/DerivedData" \
    -archivePath "../${BUILD_DIR}/${APP_NAME}.xcarchive" \
    archive

# Export the app
xcodebuild -exportArchive \
    -archivePath "../${BUILD_DIR}/${APP_NAME}.xcarchive" \
    -exportPath "../${BUILD_DIR}" \
    -exportOptionsPlist "../scripts/ExportOptions.plist"

cd ..

echo "📦 Creating DMG..."

# Create temporary DMG directory
DMG_TEMP="${BUILD_DIR}/dmg_temp"
mkdir -p "${DMG_TEMP}"

# Copy app to temp directory
cp -R "${BUILD_DIR}/${APP_NAME}.app" "${DMG_TEMP}/"

# Create Applications symlink
ln -s /Applications "${DMG_TEMP}/Applications"

# Create DMG
hdiutil create -volname "${VOLUME_NAME}" \
    -srcfolder "${DMG_TEMP}" \
    -ov -format UDZO \
    "${BUILD_DIR}/${DMG_NAME}"

echo "✅ DMG created: ${BUILD_DIR}/${DMG_NAME}"

# Generate appcast (if generate_appcast tool is available)
if command -v generate_appcast &> /dev/null; then
    echo "📝 Generating appcast..."
    generate_appcast "${BUILD_DIR}"
else
    echo "⚠️  generate_appcast not found. Install Sparkle tools to generate appcast."
    echo "   Download from: https://github.com/sparkle-project/Sparkle/releases"
fi

echo "🎉 Build complete!"

