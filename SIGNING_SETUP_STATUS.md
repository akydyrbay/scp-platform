# Android Signing Setup - Status Report

## ✅ Completed Steps

### Step 1: Scripts Created ✓
- ✅ `scp-consumer-app/android/scripts/generate-keystore.sh` - Consumer keystore generator
- ✅ `scp-supplier-sales-app/android/scripts/generate-keystore.sh` - Supplier keystore generator
- ✅ `scripts/setup-android-signing.sh` - Complete automated setup script
- ✅ All scripts are executable

### Step 2: CI Workflow Updated ✓
- ✅ Updated `.github/workflows/ci.yml` with signing configuration
- ✅ Added conditional signing setup (only runs if secrets are configured)
- ✅ Added signature verification steps
- ✅ Works with or without secrets (gracefully falls back to debug signing)

### Step 3: Documentation Created ✓
- ✅ `ANDROID_SIGNING_SETUP.md` - Complete setup guide
- ✅ `SIGNING_SETUP_STATUS.md` - This status file

---

## 🔄 Next Steps (You Need to Do)

### **Action Required 1: Generate Keystores**

**Option A: Use the automated script (recommended)**
```bash
./scripts/setup-android-signing.sh
```

**Option B: Manual generation**
```bash
# Consumer App
cd scp-consumer-app/android
./scripts/generate-keystore.sh

# Supplier App  
cd scp-supplier-sales-app/android
./scripts/generate-keystore.sh
```

**You'll be prompted for:**
- Keystore password (remember this!)
- Key password (can be same)
- Your name and organization details

---

### **Action Required 2: Configure Local Signing**

After keystores are created, the script will help you create `key.properties` files, or you can do it manually:

```bash
# Consumer App
cd scp-consumer-app/android
cp key.properties.example key.properties
# Edit key.properties with your passwords

# Supplier App
cd scp-supplier-sales-app/android  
cp key.properties.example key.properties
# Edit key.properties with your passwords
```

---

### **Action Required 3: Add GitHub Secrets**

1. **Encode keystores to base64:**
   ```bash
   # Consumer
   base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks | pbcopy
   
   # Supplier
   base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks | pbcopy
   ```

2. **Go to GitHub:**
   - Navigate to: `https://github.com/akydyrbay/scp-platform/settings/secrets/actions`
   
3. **Add these 6 secrets:**
   - `CONSUMER_KEYSTORE_BASE64` → (paste base64 from step 1)
   - `CONSUMER_KEYSTORE_PASSWORD` → your_keystore_password
   - `CONSUMER_KEY_PASSWORD` → your_key_password
   - `SUPPLIER_KEYSTORE_BASE64` → (paste base64 from step 1)
   - `SUPPLIER_KEYSTORE_PASSWORD` → your_keystore_password
   - `SUPPLIER_KEY_PASSWORD` → your_key_password

---

### **Action Required 4: Test Local Build**

```bash
cd scp-consumer-app
flutter build apk --release
```

**Verify it's signed:**
```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

Should see:
```
Verified using v1 scheme: true
Verified using v2 scheme: true
Verified using v3 scheme: true
```

---

### **Action Required 5: Push CI Changes**

```bash
git add .github/workflows/ci.yml
git add scripts/
git add *.md
git commit -m "Add Android signing configuration for CI"
git push
```

After pushing, CI will:
- ✅ Check for signing secrets
- ✅ Set up signing if secrets exist
- ✅ Build signed APKs
- ✅ Verify signatures
- ✅ Upload as artifacts

---

## 📊 Current Status

| Component | Status | Notes |
|-----------|--------|-------|
| **Scripts** | ✅ Ready | All scripts created and executable |
| **CI Workflow** | ✅ Updated | Configured with conditional signing |
| **Keystores** | ⏳ Pending | Need to generate (Action Required 1) |
| **Local Config** | ⏳ Pending | Need key.properties (Action Required 2) |
| **GitHub Secrets** | ⏳ Pending | Need to add (Action Required 3) |
| **Local Test** | ⏳ Pending | Test after keystores (Action Required 4) |

---

## 🎯 Quick Command Reference

```bash
# Generate all keystores and config
./scripts/setup-android-signing.sh

# Generate Consumer keystore only
cd scp-consumer-app/android && ./scripts/generate-keystore.sh

# Generate Supplier keystore only
cd scp-supplier-sales-app/android && ./scripts/generate-keystore.sh

# Build and verify signed APK
cd scp-consumer-app
flutter build apk --release
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk

# Encode keystore for GitHub
base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks | pbcopy
```

---

## ⚠️ Important Notes

1. **Keystores are NOT in git** - They're in `.gitignore`
2. **key.properties are NOT in git** - Also in `.gitignore`
3. **Never commit keystores or passwords**
4. **Back up keystores securely** - If lost, you can't update Play Store apps
5. **CI works without secrets** - Falls back to debug signing (not for production)

---

## 📚 Documentation

- **`ANDROID_SIGNING_SETUP.md`** - Complete setup guide
- **`TESTING_ARTIFACTS.md`** - Section on signing (already has this)
- **`README.md`** - General project documentation

---

## ✨ What Happens After Setup

Once you complete the actions above:

1. **Local builds** → Will be signed with your release key
2. **CI builds** → Will automatically sign APKs before uploading
3. **APK artifacts** → Can be installed on any Android device
4. **Play Store** → Ready for upload (when you're ready)

---

**Status:** Infrastructure ready, awaiting keystore generation and GitHub secrets configuration.

