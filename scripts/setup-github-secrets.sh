#!/bin/bash

# Script to help set up GitHub Secrets for Android signing
# This script generates a keystore and provides instructions for adding secrets to GitHub

set -e

echo "🔐 Android Signing Setup for GitHub Actions"
echo "==========================================="
echo ""

# Check if keytool is available
if ! command -v keytool &> /dev/null; then
    echo "❌ Error: keytool not found. Please install Java JDK."
    exit 1
fi

# Configuration
KEYSTORE_NAME="android-release-keystore.jks"
KEY_ALIAS="release-key"
VALIDITY_DAYS=10000

echo "This script will help you set up Android signing for GitHub Actions."
echo ""
read -p "Enter keystore password (min 6 characters): " KEYSTORE_PASSWORD
read -p "Enter key password (min 6 characters): " KEY_PASSWORD
read -p "Enter your name/organization [SCP Platform]: " ORGANIZATION
ORGANIZATION=${ORGANIZATION:-SCP Platform}

echo ""
echo "Generating keystore..."

# Generate keystore
keytool -genkey -v \
  -keystore "$KEYSTORE_NAME" \
  -storepass "$KEYSTORE_PASSWORD" \
  -keypass "$KEY_PASSWORD" \
  -alias "$KEY_ALIAS" \
  -keyalg RSA \
  -keysize 2048 \
  -validity $VALIDITY_DAYS \
  -dname "CN=$ORGANIZATION, OU=Mobile, O=$ORGANIZATION, L=City, ST=State, C=US"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Keystore generated successfully: $KEYSTORE_NAME"
    echo ""
    echo "📋 Next Steps:"
    echo ""
    echo "1. Add the following secrets to your GitHub repository:"
    echo "   - Go to: Settings → Secrets and variables → Actions"
    echo ""
    echo "2. Add these secrets:"
    echo ""
    echo "   Secret Name: ANDROID_KEYSTORE_PASSWORD"
    echo "   Secret Value: $KEYSTORE_PASSWORD"
    echo ""
    echo "   Secret Name: ANDROID_KEY_PASSWORD"
    echo "   Secret Value: $KEY_PASSWORD"
    echo ""
    echo "   Secret Name: ANDROID_KEY_ALIAS"
    echo "   Secret Value: $KEY_ALIAS"
    echo ""
    echo "3. (Optional) If you want to use a custom keystore file:"
    echo "   - Encode the keystore to base64:"
    echo "     base64 -i $KEYSTORE_NAME | pbcopy"
    echo "   - Add as secret: ANDROID_KEYSTORE_BASE64"
    echo ""
    echo "⚠️  IMPORTANT:"
    echo "   - Keep the keystore file ($KEYSTORE_NAME) safe and secure"
    echo "   - Do NOT commit the keystore file to git"
    echo "   - Store passwords securely (use a password manager)"
    echo "   - If you lose the keystore, you won't be able to update your app"
    echo ""
    echo "📝 The keystore file has been created in the current directory."
    echo "   Make sure to add it to .gitignore if not already excluded."
else
    echo ""
    echo "❌ Failed to generate keystore. Please check the error above."
    exit 1
fi

