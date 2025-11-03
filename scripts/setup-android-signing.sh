#!/bin/bash

# Complete Android signing setup script
# This script guides you through the entire signing setup process

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "🔐 Android Signing Setup Script"
echo "================================"
echo ""

# Step 1: Generate Keystores
echo "Step 1: Generate Keystores"
echo "---------------------------"
echo ""

# Consumer App
echo "📱 Consumer App Keystore"
read -p "Generate keystore for Consumer App? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cd "$PROJECT_ROOT/scp-consumer-app/android"
    if [ -f "scripts/generate-keystore.sh" ]; then
        chmod +x scripts/generate-keystore.sh
        ./scripts/generate-keystore.sh
    else
        echo "⚠️  Script not found. Running keytool directly..."
        mkdir -p keystores
        keytool -genkey -v \
          -keystore keystores/consumer-release-key.jks \
          -keyalg RSA \
          -keysize 2048 \
          -validity 10000 \
          -alias scp_consumer_key \
          -storetype JKS
    fi
fi

echo ""
echo "📱 Supplier Sales App Keystore"
read -p "Generate keystore for Supplier App? (Y/n): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Nn]$ ]]; then
    cd "$PROJECT_ROOT/scp-supplier-sales-app/android"
    if [ -f "scripts/generate-keystore.sh" ]; then
        chmod +x scripts/generate-keystore.sh
        ./scripts/generate-keystore.sh
    else
        echo "⚠️  Script not found. Running keytool directly..."
        mkdir -p keystores
        keytool -genkey -v \
          -keystore keystores/supplier-release-key.jks \
          -keyalg RSA \
          -keysize 2048 \
          -validity 10000 \
          -alias scp_supplier_key \
          -storetype JKS
    fi
fi

echo ""
echo "Step 2: Configure Local Signing"
echo "--------------------------------"
echo ""

# Consumer App key.properties
cd "$PROJECT_ROOT/scp-consumer-app/android"
if [ ! -f "key.properties" ]; then
    if [ -f "keystores/consumer-release-key.jks" ]; then
        echo "📝 Creating key.properties for Consumer App..."
        echo "Please enter your keystore details:"
        read -sp "Keystore password: " STORE_PASS
        echo
        read -sp "Key password (press Enter to use keystore password): " KEY_PASS
        echo
        if [ -z "$KEY_PASS" ]; then
            KEY_PASS="$STORE_PASS"
        fi
        
        cat > key.properties << EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=scp_consumer_key
storeFile=../keystores/consumer-release-key.jks
EOF
        echo "✅ Created key.properties for Consumer App"
    else
        echo "⚠️  Consumer keystore not found. Skipping key.properties creation."
    fi
else
    echo "ℹ️  key.properties already exists for Consumer App"
fi

# Supplier App key.properties
cd "$PROJECT_ROOT/scp-supplier-sales-app/android"
if [ ! -f "key.properties" ]; then
    if [ -f "keystores/supplier-release-key.jks" ]; then
        echo "📝 Creating key.properties for Supplier App..."
        echo "Please enter your keystore details:"
        read -sp "Keystore password: " STORE_PASS
        echo
        read -sp "Key password (press Enter to use keystore password): " KEY_PASS
        echo
        if [ -z "$KEY_PASS" ]; then
            KEY_PASS="$STORE_PASS"
        fi
        
        cat > key.properties << EOF
storePassword=$STORE_PASS
keyPassword=$KEY_PASS
keyAlias=scp_supplier_key
storeFile=../keystores/supplier-release-key.jks
EOF
        echo "✅ Created key.properties for Supplier App"
    else
        echo "⚠️  Supplier keystore not found. Skipping key.properties creation."
    fi
else
    echo "ℹ️  key.properties already exists for Supplier App"
fi

echo ""
echo "Step 3: Prepare for CI/CD"
echo "-------------------------"
echo ""

cd "$PROJECT_ROOT"

# Base64 encode keystores
if [ -f "scp-consumer-app/android/keystores/consumer-release-key.jks" ]; then
    echo "📦 Encoding Consumer keystore for GitHub Secrets..."
    if command -v base64 &> /dev/null; then
        base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks > consumer-keystore-base64.txt 2>/dev/null || \
        base64 scp-consumer-app/android/keystores/consumer-release-key.jks > consumer-keystore-base64.txt
        echo "✅ Consumer keystore encoded to: consumer-keystore-base64.txt"
        echo "   Copy this file's contents to GitHub Secret: CONSUMER_KEYSTORE_BASE64"
    else
        echo "⚠️  base64 command not found. Please encode manually:"
        echo "   base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks"
    fi
fi

if [ -f "scp-supplier-sales-app/android/keystores/supplier-release-key.jks" ]; then
    echo "📦 Encoding Supplier keystore for GitHub Secrets..."
    if command -v base64 &> /dev/null; then
        base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks > supplier-keystore-base64.txt 2>/dev/null || \
        base64 scp-supplier-sales-app/android/keystores/supplier-release-key.jks > supplier-keystore-base64.txt
        echo "✅ Supplier keystore encoded to: supplier-keystore-base64.txt"
        echo "   Copy this file's contents to GitHub Secret: SUPPLIER_KEYSTORE_BASE64"
    else
        echo "⚠️  base64 command not found. Please encode manually:"
        echo "   base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks"
    fi
fi

echo ""
echo "✅ Setup Complete!"
echo ""
echo "📋 Next Steps:"
echo "  1. Add GitHub Secrets (see TESTING_ARTIFACTS.md Step 4.2)"
echo "  2. CI workflow is already updated - push changes to trigger signed builds"
echo "  3. Test local build: cd scp-consumer-app && flutter build apk --release"
echo ""

