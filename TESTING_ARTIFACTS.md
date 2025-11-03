# Testing CI/CD Artifacts on Your Phone

## ⚠️ Important Differences: iOS vs Android

### **iOS (IPA/APP) - ❌ Cannot Test Directly**

**Your CI built with `--no-codesign`:**
```yaml
flutter build ios --release --dart-define=ENV=production --no-codesign
```

**What this means:**
1. ❌ **The iOS artifact is NOT signed** - You cannot install it on any iPhone
2. ❌ **iOS requires Apple Developer account** ($99/year) for code signing
3. ❌ **Even if signed, you can't just download and install** - iOS requires:
   - **TestFlight** (for beta testing)
   - **App Store** (for production)
   - **Ad-hoc distribution** (requires device UDIDs registered)
   - **Enterprise distribution** (requires enterprise account, $299/year)

**Why you can't use the artifact:**
- The artifact is `Runner.app`, not a proper `.ipa` file
- Even if it was an `.ipa`, it's unsigned
- iOS blocks unsigned apps from installing on devices
- No workaround without Apple Developer account setup

---

### **Android (APK) - ✅ Can Test (with caveats)**

**Your CI builds release APKs:**
```yaml
flutter build apk --release --dart-define=ENV=production
```

**What this means:**
1. ✅ **APK can be downloaded and installed** on Android devices
2. ⚠️ **Release APKs need to be signed** for proper installation
3. ✅ **Debug APKs can be installed without signing**

---

## 📱 How to Test Android APK

### **Option 1: Download from GitHub Actions** ✅ **RECOMMENDED**

1. **Go to your GitHub Actions run:**
   - Navigate to: `https://github.com/akydyrbay/scp-platform/actions`
   - Click on the successful run
   - Scroll to "Artifacts" section

2. **Download the APK:**
   - Find `consumer-apk` or `supplier-apk` artifact
   - Click to download (zip file)

3. **Extract and Install:**
   ```bash
   # Extract the zip file
   unzip consumer-apk.zip
   
   # You'll find: app-release.apk
   ```

4. **Install on Android Phone:**
   - Transfer `app-release.apk` to your phone
   - **Enable "Install from Unknown Sources"**:
     - Settings → Security → Enable "Install unknown apps"
     - Or Settings → Apps → Special access → Install unknown apps
   - Tap the APK file to install
   - Follow installation prompts

**⚠️ Note:** If installation fails with "App not installed" or "Package appears to be invalid":
- The APK might not be properly signed
- Release builds need a signing key

---

### **Option 2: Build Debug APK Locally** ✅ **EASIEST FOR TESTING**

Build a debug APK which doesn't require signing:

```bash
cd scp-consumer-app
flutter build apk --debug
# APK location: build/app/outputs/flutter-apk/app-debug.apk
```

**Advantages:**
- ✅ No signing required
- ✅ Faster build
- ✅ Can install directly
- ✅ Includes debug symbols

**Disadvantages:**
- ⚠️ Larger file size
- ⚠️ Not optimized for production

**Install:**
```bash
# Transfer to phone and install
adb install build/app/outputs/flutter-apk/app-debug.apk
# Or manually transfer APK file to phone
```

---

### **Option 3: Build Release APK with Signing** ✅ **PRODUCTION-READY**

If you want to test a properly signed release APK:

1. **Set up signing keys** (if not already done):
   ```bash
   # Create keystore
   keytool -genkey -v -keystore ~/consumer-release-key.jks \
     -keyalg RSA -keysize 2048 -validity 10000 \
     -alias scp_consumer_key
   ```

2. **Configure key.properties:**
   ```properties
   storePassword=your_store_password
   keyPassword=your_key_password
   keyAlias=scp_consumer_key
   storeFile=/path/to/consumer-release-key.jks
   ```

3. **Build signed release:**
   ```bash
   cd scp-consumer-app
   flutter build apk --release
   ```

4. **Install:**
   ```bash
   adb install build/app/outputs/flutter-apk/app-release.apk
   ```

---

## 🍎 Testing iOS Builds

### **Requirements:**
- ✅ Apple Developer Account ($99/year)
- ✅ Xcode installed (on Mac)
- ✅ Your iPhone's UDID registered

### **Option 1: TestFlight** (Recommended for Beta Testing)

1. **Configure signing in Xcode:**
   ```bash
   cd scp-consumer-app
   open ios/Runner.xcworkspace
   ```
   - Select Runner target
   - Signing & Capabilities → Enable "Automatically manage signing"
   - Select your Team

2. **Build and Archive:**
   ```bash
   flutter build ios --release
   # Then in Xcode: Product → Archive
   ```

3. **Upload to TestFlight:**
   - Xcode → Window → Organizer
   - Select archive → "Distribute App"
   - Choose "TestFlight & App Store"
   - Upload and wait for processing
   - Add testers in App Store Connect

4. **Install on iPhone:**
   - TestFlight app will show your app
   - Tap "Install" to download

---

### **Option 2: Direct Install via Xcode** (For Development)

1. **Connect iPhone to Mac**

2. **Build and Run:**
   ```bash
   flutter run --release
   # Or in Xcode: Select your iPhone as target and click Run
   ```

3. **Trust Developer Certificate:**
   - On iPhone: Settings → General → VPN & Device Management
   - Trust your developer certificate

---

### **Option 3: Ad-hoc Distribution** (Limited Testing)

1. **Register Device UDIDs** in Apple Developer Portal

2. **Create Ad-hoc Provisioning Profile** (includes your devices)

3. **Build and Sign:**
   ```bash
   flutter build ios --release
   # Then export with ad-hoc profile in Xcode
   ```

4. **Install:**
   - Transfer `.ipa` to iPhone (via email, AirDrop, or web)
   - Install via Settings or using tools like `ios-deploy`

---

## 🔍 Current CI Build Status

### **Android Builds:**
- ✅ Building release APKs
- ⚠️ **May not be properly signed** (check if keystores are configured in CI)
  - See [How to Check and Configure Signing](#how-to-check-and-configure-android-signing) below
- ✅ Artifacts can be downloaded and tested (if signed)

### **iOS Builds:**
- ✅ Building iOS release
- ❌ **Using `--no-codesign`** - Not signed
- ❌ **Artifact is `.app` bundle, not `.ipa`**
- ❌ **Cannot be installed on device without signing**

---

## ✅ Recommended Testing Workflow

### **For Quick Testing (No Setup):**
1. Build debug APK locally:
   ```bash
   flutter build apk --debug
   ```
2. Install on Android phone
3. Test functionality

### **For Production-Like Testing:**
1. Set up Android signing (keystores)
2. Build release APK with signing
3. Test on Android devices
4. For iOS: Set up Apple Developer account → Use TestFlight

### **For CI Artifacts:**
1. **Android:** Download APK from artifacts → Install (if signed)
2. **iOS:** Cannot test - requires signing setup first

---

## 🛠️ Fixing CI Builds for Testing

### **To Enable Proper Android Testing:**

Update `.github/workflows/ci.yml`:

```yaml
- name: Build Consumer APK
  run: |
    cd scp-consumer-app
    # Build debug APK for testing (no signing needed)
    flutter build apk --debug --dart-define=ENV=production
    # Or build release with signing if keystores are configured
    # flutter build apk --release --dart-define=ENV=production
```

### **To Enable iOS Testing:**

1. **Add signing secrets to GitHub:**
   - Settings → Secrets and variables → Actions
   - Add: `APPLE_DEVELOPER_CERT`, `APPLE_DEVELOPER_KEY`, etc.

2. **Update CI to sign iOS builds:**
   ```yaml
   - name: Setup Code Signing
     # Add signing setup steps
   
   - name: Build Consumer iOS
     run: |
       cd scp-consumer-app
       flutter build ios --release --dart-define=ENV=production
       # Archive and export IPA
   ```

---

## 🔐 How to Check and Configure Android Signing

### **Step 1: Check if APK is Signed**

#### **Method 1: Using `apksigner` (Android SDK)**
```bash
# Check if APK is signed
apksigner verify --verbose app-release.apk

# Expected output if signed:
# Verifies
# Verified using v1 scheme (JAR signing): true
# Verified using v2 scheme (APK Signature Scheme v2): true
# Verified using v3 scheme (APK Signature Scheme v3): true
# Number of signers: 1

# If NOT signed, you'll see:
# ERROR: JAR signer CERT.RSA: JAR signature META-INF/MANIFEST.MF indicates the APK is not signed
```

#### **Method 2: Using `jarsigner` (Java JDK)**
```bash
jarsigner -verify -verbose -certs app-release.apk

# If signed, you'll see: "jar verified."
# If NOT signed, you'll see: "jar is unsigned."
```

#### **Method 3: Try Installing**
- If APK installation fails with "App not installed" or "Package appears to be invalid"
- It's likely unsigned or signed with debug key

---

### **Step 2: Create Keystores (If Not Already Done)**

Create separate keystores for each app:

#### **For Consumer App:**
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

**You'll be prompted for:**
- Keystore password (remember this!)
- Key password (can be same as keystore)
- Your name and organization details

#### **For Supplier App:**
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
- Keep keystores safe - you'll need them for all future releases
- If you lose the keystore, you can't update your app on Play Store
- Back up keystores securely

---

### **Step 3: Configure Local Signing (For Testing)**

#### **Create `key.properties` files:**

**Consumer App:**
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

**Supplier App:**
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

**⚠️ Security:**
- `key.properties` is in `.gitignore` - don't commit it!
- Keep passwords secure

#### **Test Local Build:**
```bash
cd scp-consumer-app
flutter build apk --release
```

Verify it's signed:
```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

---

### **Step 4: Configure CI/CD Signing (GitHub Actions)**

#### **4.1: Create Base64-Encoded Keystores**

Convert keystores to base64 for GitHub Secrets:

**On Mac/Linux:**
```bash
# Consumer keystore
base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks | pbcopy

# Supplier keystore
base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks | pbcopy
```

**Or save to file:**
```bash
base64 -i scp-consumer-app/android/keystores/consumer-release-key.jks > consumer-keystore-base64.txt
base64 -i scp-supplier-sales-app/android/keystores/supplier-release-key.jks > supplier-keystore-base64.txt
```

#### **4.2: Add GitHub Secrets**

1. Go to your repository: `https://github.com/akydyrbay/scp-platform`

2. Navigate to: **Settings → Secrets and variables → Actions**

3. **Important:** Choose **"Repository secrets"** (NOT "Environment secrets")
   - Repository secrets are for repository-wide use
   - Environment secrets are for specific deployment environments
   - Since we want signing for all CI builds, use Repository secrets

4. Click **"New repository secret"** for each secret below

5. Add these 6 secrets with exact names (case-sensitive):

   | Secret Name | Value | Description |
   |------------|-------|-------------|
   | `CONSUMER_KEYSTORE_BASE64` | (paste base64 keystore) | Base64-encoded consumer keystore |
   | `CONSUMER_KEYSTORE_PASSWORD` | your_keystore_password | Consumer keystore password |
   | `CONSUMER_KEY_PASSWORD` | your_key_password | Consumer key password |
   | `SUPPLIER_KEYSTORE_BASE64` | (paste base64 keystore) | Base64-encoded supplier keystore |
   | `SUPPLIER_KEYSTORE_PASSWORD` | your_keystore_password | Supplier keystore password |
   | `SUPPLIER_KEY_PASSWORD` | your_key_password | Supplier key password |

6. **Naming Rules:**
   - ✅ Use exact names as shown above (case-sensitive)
   - ✅ No spaces or special characters
   - ✅ All uppercase with underscores

7. **For each secret:**
   - Click **"New repository secret"**
   - Enter the **Name** (exact match from table)
   - Paste/enter the **Value**
   - Click **"Add secret"**

**⚠️ Important:**
- Use **Repository secrets**, not Environment secrets
- Names must match exactly (case-sensitive)
- Values are masked and encrypted by GitHub

---

### **Step 5: Update CI Workflow**

Update `.github/workflows/ci.yml`:

```yaml
  build-android:
    name: Build Android APK
    runs-on: ubuntu-latest
    needs: [analyze, test]  
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v4
      
      - name: Setup Flutter
        uses: subosito/flutter-action@v2
        with:
          channel: 'stable'
          cache: true
      
      - name: Setup Java
        uses: actions/setup-java@v4
        with:
          distribution: 'zulu'
          java-version: '17'
      
      - name: Install dependencies
        run: |
          cd scp-mobile-shared && flutter pub get
          cd ../scp-consumer-app && flutter pub get
          cd ../scp-supplier-sales-app && flutter pub get
      
      # Consumer App Signing Setup
      - name: Setup Consumer Keystore
        working-directory: scp-consumer-app/android
        run: |
          echo "${{ secrets.CONSUMER_KEYSTORE_BASE64 }}" | base64 -d > keystores/consumer-release-key.jks
          cat > key.properties << EOF
          storePassword=${{ secrets.CONSUMER_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.CONSUMER_KEY_PASSWORD }}
          keyAlias=scp_consumer_key
          storeFile=../keystores/consumer-release-key.jks
          EOF
      
      # Supplier App Signing Setup
      - name: Setup Supplier Keystore
        working-directory: scp-supplier-sales-app/android
        run: |
          echo "${{ secrets.SUPPLIER_KEYSTORE_BASE64 }}" | base64 -d > keystores/supplier-release-key.jks
          cat > key.properties << EOF
          storePassword=${{ secrets.SUPPLIER_KEYSTORE_PASSWORD }}
          keyPassword=${{ secrets.SUPPLIER_KEY_PASSWORD }}
          keyAlias=scp_supplier_key
          storeFile=../keystores/supplier-release-key.jks
          EOF
      
      - name: Build Consumer APK
        run: |
          cd scp-consumer-app
          flutter build apk --release --dart-define=ENV=production
      
      - name: Build Supplier APK
        run: |
          cd scp-supplier-sales-app
          flutter build apk --release --dart-define=ENV=production
      
      # Verify APKs are signed
      - name: Verify Consumer APK Signature
        run: |
          apksigner verify --verbose scp-consumer-app/build/app/outputs/flutter-apk/app-release.apk || echo "APK verification failed"
      
      - name: Verify Supplier APK Signature
        run: |
          apksigner verify --verbose scp-supplier-sales-app/build/app/outputs/flutter-apk/app-release.apk || echo "APK verification failed"
      
      - name: Upload Consumer APK
        uses: actions/upload-artifact@v4
        with:
          name: consumer-apk
          path: scp-consumer-app/build/app/outputs/flutter-apk/app-release.apk
      
      - name: Upload Supplier APK
        uses: actions/upload-artifact@v4
        with:
          name: supplier-apk
          path: scp-supplier-sales-app/build/app/outputs/flutter-apk/app-release.apk
```

---

### **Step 6: Verify CI Build**

1. **Push changes** to trigger CI:
   ```bash
   git add .github/workflows/ci.yml
   git commit -m "Add Android signing to CI"
   git push
   ```

2. **Check CI logs:**
   - Go to Actions tab
   - Check "Verify APK Signature" steps
   - Should see "Verified using v1/v2/v3 scheme: true"

3. **Download and test APK:**
   - Download from artifacts
   - Install on Android device
   - Should install successfully

---

### **Quick Reference: Commands**

#### **Check if APK is signed:**
```bash
# Using apksigner (recommended)
apksigner verify --verbose app-release.apk

# Using jarsigner (alternative)
jarsigner -verify -verbose app-release.apk
```

#### **Create keystore:**
```bash
keytool -genkey -v -keystore keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias key_alias
```

#### **Base64 encode keystore:**
```bash
base64 -i keystore.jks | pbcopy  # Mac
base64 -i keystore.jks           # Linux
```

#### **Decode base64 keystore:**
```bash
echo "base64_string" | base64 -d > keystore.jks
```

---

## 📋 Summary

| Platform | Can Test Artifact? | Requirements | Best Method |
|----------|-------------------|--------------|-------------|
| **Android APK** | ✅ **Yes** (if signed) | Enable unknown sources | Download from CI or build debug locally |
| **iOS IPA** | ❌ **No** (not signed) | Apple Developer account, Xcode | Use TestFlight or build locally with Xcode |

**For immediate testing:**
- ✅ **Android:** Build debug APK locally → Install directly
- ❌ **iOS:** Not possible without Apple Developer setup

**For production testing:**
- ✅ **Android:** Set up signing → Build release APK
- ✅ **iOS:** Set up Apple Developer → Use TestFlight

