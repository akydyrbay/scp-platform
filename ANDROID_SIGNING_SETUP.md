# Android Signing Setup Guide

This guide will walk you through setting up Android app signing for both local development and CI/CD.

## 🎯 Quick Start

Run the automated setup script:

```bash
./scripts/setup-android-signing.sh
```

This script will:
1. Generate keystores for both apps
2. Create `key.properties` files
3. Encode keystores for GitHub Secrets

---

## 📋 Manual Setup Steps

### Step 1: Generate Keystores

#### Consumer App:
```bash
cd scp-consumer-app/android
./scripts/generate-keystore.sh
```

Or manually:
```bash
cd scp-consumer-app/android
mkdir -p keystores
keytool -genkey -v \
  -keystore keystores/consumer-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias scp_consumer_key \
  -storetype JKS
```

#### Supplier App:
```bash
cd scp-supplier-sales-app/android
./scripts/generate-keystore.sh
```

Or manually:
```bash
cd scp-supplier-sales-app/android
mkdir -p keystores
keytool -genkey -v \
  -keystore keystores/supplier-release-key.jks \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000 \
  -alias scp_supplier_key \
  -storetype JKS
```

**⚠️ Important:** 
- Remember your passwords!
- Keep keystores secure and backed up
- If lost, you can't update your app on Play Store

---

### Step 2: Configure Local Signing

Create `key.properties` files (not committed to git):

#### Consumer App:
```bash
cd scp-consumer-app/android
cp key.properties.example key.properties
```

Edit `key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=scp_consumer_key
storeFile=../keystores/consumer-release-key.jks
```

#### Supplier App:
```bash
cd scp-supplier-sales-app/android
cp key.properties.example key.properties
```

Edit `key.properties`:
```properties
storePassword=your_keystore_password
keyPassword=your_key_password
keyAlias=scp_supplier_key
storeFile=../keystores/supplier-release-key.jks
```

**Test local build:**
```bash
cd scp-consumer-app
flutter build apk --release
```

**Verify signing:**
```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

---

### Step 3: Configure CI/CD Signing

#### 3.1: Encode Keystores

Convert keystores to base64:

```bash
# Consumer keystore
base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks | pbcopy  # Mac
base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks           # Linux

# Supplier keystore
base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks | pbcopy  # Mac
base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks           # Linux
```

Or save to files:
```bash
base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks > consumer-keystore-base64.txt
base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks > supplier-keystore-base64.txt
```

#### 3.2: Add GitHub Secrets

1. Go to: `https://github.com/akydyrbay/scp-platform/settings/secrets/actions`

2. **Important:** Make sure you're on the **"Repository secrets"** tab (NOT "Environment secrets")
   - Repository secrets = for all CI builds in this repo
   - Environment secrets = for specific deployment environments
   - We need **Repository secrets** for signing

3. Click **"New repository secret"** for each:

   | Secret Name | Value |
   |------------|-------|
   | `CONSUMER_KEYSTORE_BASE64` | (paste base64 from step 3.1) |
   | `CONSUMER_KEYSTORE_PASSWORD` | your_keystore_password |
   | `CONSUMER_KEY_PASSWORD` | your_key_password |
   | `SUPPLIER_KEYSTORE_BASE64` | (paste base64 from step 3.1) |
   | `SUPPLIER_KEYSTORE_PASSWORD` | your_keystore_password |
   | `SUPPLIER_KEY_PASSWORD` | your_key_password |

3. Click **"Add secret"** for each

#### 3.3: CI Workflow

The CI workflow (`.github/workflows/ci.yml`) is already configured! It will:
- Automatically set up signing if secrets are present
- Build signed APKs
- Verify signatures
- Upload as artifacts

**No changes needed** - just add the secrets above.

---

## ✅ Verification

### Check if APK is Signed:

```bash
# Method 1: apksigner (recommended)
apksigner verify --verbose app-release.apk

# Method 2: jarsigner
jarsigner -verify -verbose app-release.apk
```

### Expected Output (if signed):
```
Verifies
Verified using v1 scheme (JAR signing): true
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Number of signers: 1
```

---

## 🔧 Troubleshooting

### "APK not signed" Error:
- Check `key.properties` file exists and paths are correct
- Verify keystore file exists at the specified path
- Ensure passwords are correct

### CI Build Fails:
- Check GitHub Secrets are added correctly
- Verify base64 encoding is valid (no newlines)
- Check CI logs for specific error messages

### Local Build Uses Debug Signing:
- `key.properties` might be missing or incorrect
- Check `build.gradle.kts` logs for signing config

---

## 📝 Files Created

After setup, you'll have:

```
scp-consumer-app/android/
  ├── keystores/
  │   └── consumer-release-key.jks  (NOT in git)
  └── key.properties                (NOT in git)

scp-supplier-sales-app/android/
  ├── keystores/
  │   └── supplier-release-key.jks  (NOT in git)
  └── key.properties                (NOT in git)
```

**All keystores and key.properties are in `.gitignore`** - never commit them!

---

## 🚀 Next Steps

1. ✅ Keystores generated
2. ✅ Local signing configured
3. ✅ GitHub Secrets added
4. ✅ CI workflow ready

**Push to trigger signed CI builds:**
```bash
git add .github/workflows/ci.yml
git commit -m "Configure Android signing in CI"
git push
```

Check Actions tab - APKs will now be signed! 🎉

