#!/bin/bash

# Apple Notarization Script for DesignDiff
# This script signs the app with Developer ID and submits for notarization

set -e

# Configuration
APP_NAME="DesignDiff"
BUILD_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/build"
APP_PATH="${BUILD_DIR}/${APP_NAME}.app"
DMG_PATH="${BUILD_DIR}/${APP_NAME}-1.0.0.dmg"
ZIP_PATH="${BUILD_DIR}/${APP_NAME}-1.0.0.zip"

# Check for required environment variables
if [ -z "$APPLE_ID" ]; then
    echo "❌ Error: APPLE_ID environment variable not set"
    echo "   Export your Apple ID email: export APPLE_ID='your@email.com'"
    exit 1
fi

if [ -z "$APPLE_ID_PASSWORD" ]; then
    echo "❌ Error: APPLE_ID_PASSWORD environment variable not set"
    echo "   Create an app-specific password at: https://appleid.apple.com"
    echo "   Export it: export APPLE_ID_PASSWORD='xxxx-xxxx-xxxx-xxxx'"
    exit 1
fi

if [ -z "$APPLE_TEAM_ID" ]; then
    echo "❌ Error: APPLE_TEAM_ID environment variable not set"
    echo "   Find your Team ID at: https://developer.apple.com/account"
    echo "   Export it: export APPLE_TEAM_ID='XXXXXXXXXX'"
    exit 1
fi

echo "🔍 Checking for Developer ID certificate..."
DEVELOPER_ID=$(security find-identity -v -p codesigning | grep "Developer ID Application" | head -1 | grep -o '"[^"]*"' | sed 's/"//g')

if [ -z "$DEVELOPER_ID" ]; then
    echo "❌ No Developer ID Application certificate found"
    echo ""
    echo "📝 To get a Developer ID certificate:"
    echo "   1. Go to https://developer.apple.com/account/resources/certificates/list"
    echo "   2. Click '+' to create a new certificate"
    echo "   3. Select 'Developer ID Application'"
    echo "   4. Download and install the certificate"
    echo ""
    exit 1
fi

echo "✅ Found certificate: $DEVELOPER_ID"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "❌ App not found: $APP_PATH"
    echo "   Run ./scripts/create-dmg.sh first"
    exit 1
fi

echo ""
echo "🔐 Step 1: Signing the app with Developer ID..."
codesign --force --deep --sign "$DEVELOPER_ID" \
    --options runtime \
    --entitlements "../DesignDiff/DesignDiff/DesignDiff.entitlements" \
    "$APP_PATH"

echo "✅ App signed successfully"

echo ""
echo "📦 Step 2: Creating ZIP archive for notarization..."
cd "$BUILD_DIR"
ditto -c -k --keepParent "${APP_NAME}.app" "$(basename "$ZIP_PATH")"
echo "✅ ZIP created: $ZIP_PATH"

echo ""
echo "📤 Step 3: Submitting for notarization..."
echo "   This may take a few minutes..."

xcrun notarytool submit "$ZIP_PATH" \
    --apple-id "$APPLE_ID" \
    --password "$APPLE_ID_PASSWORD" \
    --team-id "$APPLE_TEAM_ID" \
    --wait

echo ""
echo "📋 Step 4: Stapling notarization ticket to app..."
xcrun stapler staple "$APP_PATH"
echo "✅ Notarization ticket stapled"

echo ""
echo "📦 Step 5: Creating notarized DMG..."
# Remove old DMG if exists
[ -f "$DMG_PATH" ] && rm "$DMG_PATH"

# Create temporary directory for DMG
DMG_TEMP="${BUILD_DIR}/dmg_temp_notarized"
rm -rf "$DMG_TEMP"
mkdir -p "$DMG_TEMP"

# Copy notarized app
cp -R "$APP_PATH" "$DMG_TEMP/"

# Create Applications symlink
ln -s /Applications "$DMG_TEMP/Applications"

# Create DMG
hdiutil create -volname "${APP_NAME} 1.0.0" \
    -srcfolder "$DMG_TEMP" \
    -ov -format UDZO \
    "$DMG_PATH"

# Clean up
rm -rf "$DMG_TEMP"

echo "✅ Notarized DMG created: $DMG_PATH"

echo ""
echo "🎉 Notarization complete!"
echo ""
echo "📝 Next steps:"
echo "   1. Test the app: open '$APP_PATH'"
echo "   2. Upload to GitHub Releases: $DMG_PATH"
echo "   3. Generate appcast: ./scripts/generate-appcast.sh"
echo ""
echo "⚠️  Note: Keep your APPLE_ID_PASSWORD secure. Consider using:"
echo "   security add-generic-password -a '$APPLE_ID' -w 'password' -s 'notarization-password'"

