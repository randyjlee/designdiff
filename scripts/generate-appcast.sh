#!/bin/bash

# Generate appcast.xml for Sparkle updates
# This script creates a basic appcast.xml file

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/../build"
APP_NAME="DesignDiff"
VERSION="1.0.0"
DMG_NAME="${APP_NAME}-${VERSION}.dmg"
REPO_URL="https://github.com/randyjlee/designdiff"
PUBLIC_KEY="aM3QGDzAhGJWfSiS8H5Dln8bmORrMOJiOE9+zZBi26s="

# Get DMG size and date
DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
if [ ! -f "$DMG_PATH" ]; then
    echo "❌ DMG file not found: $DMG_PATH"
    exit 1
fi

DMG_SIZE=$(stat -f%z "$DMG_PATH")
DMG_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")

# Create appcast.xml
cat > "${BUILD_DIR}/appcast.xml" <<EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
    <channel>
        <title>DesignDiff</title>
        <link>${REPO_URL}</link>
        <description>Most recent changes with links to updates.</description>
        <language>en</language>
        <item>
            <title>Version ${VERSION}</title>
            <sparkle:releaseNotesLink>${REPO_URL}/releases/tag/v${VERSION}</sparkle:releaseNotesLink>
            <pubDate>${DMG_DATE}</pubDate>
            <enclosure url="${REPO_URL}/releases/download/v${VERSION}/${DMG_NAME}"
                       sparkle:version="1"
                       sparkle:shortVersionString="${VERSION}"
                       length="${DMG_SIZE}"
                       type="application/octet-stream"
                       sparkle:edSignature="${PUBLIC_KEY}" />
        </item>
    </channel>
</rss>
EOF

echo "✅ Appcast created: ${BUILD_DIR}/appcast.xml"
echo ""
echo "⚠️  Note: You need to sign the appcast with your private key using generate_appcast"
echo "   For now, this is a basic unsigned appcast. Sparkle will verify the DMG signature."

