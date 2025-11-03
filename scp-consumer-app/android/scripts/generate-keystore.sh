#!/bin/bash

# Script to generate Android keystore for Consumer App
# Usage: ./generate-keystore.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANDROID_DIR="$(dirname "$SCRIPT_DIR")"
KEYSTORE_DIR="$ANDROID_DIR/keystores"
KEYSTORE_FILE="$KEYSTORE_DIR/consumer-release-key.jks"

# Create keystores directory if it doesn't exist
mkdir -p "$KEYSTORE_DIR"

# Check if keystore already exists
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  Keystore already exists at: $KEYSTORE_FILE"
    read -p "Do you want to overwrite it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "❌ Keystore generation cancelled."
        exit 0
    fi
    rm -f "$KEYSTORE_FILE"
fi

echo "🔑 Generating Android keystore for Consumer App..."
echo "📍 Location: $KEYSTORE_FILE"
echo ""
echo "You will be prompted for:"
echo "  - Keystore password (remember this!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name and organization details"
echo ""

# Generate keystore
keytool -genkey -v \
  -keystore "$KEYSTORE_FILE" \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias scp_consumer_key \
  -storetype JKS

echo ""
echo "✅ Keystore created successfully!"
echo "📍 Location: $KEYSTORE_FILE"
echo ""
echo "⚠️  IMPORTANT:"
echo "   - Keep this keystore file safe!"
echo "   - You'll need it for all future releases"
echo "   - If you lose it, you can't update your app on Play Store"
echo "   - Back it up securely!"
echo ""
echo "Next steps:"
echo "  1. Configure key.properties (see key.properties.example)"
echo "  2. Build release APK: flutter build apk --release"
echo "  3. For CI: Base64 encode this keystore and add to GitHub Secrets"

