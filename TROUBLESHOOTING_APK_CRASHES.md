# Troubleshooting APK Crashes on Startup

## Common Reasons Why APK Crashes Immediately After Installation

### 1. **Missing Error Handling in `main()` Function** ⚠️ CRITICAL

**Problem:** If `StorageService.init()` or any initialization throws an exception, the app crashes silently.

**Current Code:**
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppConfig.initialize();
  final storageService = StorageService();
  await storageService.init(); // ⚠️ No try-catch!
  runApp(const SCPConsumerApp());
}
```

**Solution:** Add error handling:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    AppConfig.initialize();
    final storageService = StorageService();
    await storageService.init();
    runApp(const SCPConsumerApp());
  } catch (e, stackTrace) {
    // Log error or show error screen
    print('App initialization error: $e');
    runApp(ErrorApp(error: e));
  }
}
```

---

### 2. **ProGuard/R8 Removing Required Classes** ⚠️ HIGH PRIORITY

**Problem:** Release builds use R8 minification which might remove classes needed at runtime.

**Potential Issues:**
- Model classes for JSON serialization not kept
- Flutter plugin classes removed
- Reflection-based code removed (e.g., JSON parsing)

**Solution:** Add more ProGuard rules:

```proguard
# Keep all model classes from shared package
-keep class scp_mobile_shared.** { *; }
-dontwarn scp_mobile_shared.**

# Keep classes used for JSON serialization
-keepattributes Signature
-keepattributes *Annotation*
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep data classes
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep Flutter generated files
-keep class **.generated.** { *; }

# Keep localization classes
-keep class **.generated.l10n.** { *; }
```

---

### 3. **Missing Localization Files** ⚠️ HIGH PRIORITY

**Problem:** The app imports `generated/l10n/app_localizations.dart` but these files might not be generated in release builds.

**Symptoms:**
- `NoSuchMethodError` when accessing `AppLocalizations`
- `MissingPluginException` related to localization

**Solution:**
1. Ensure localization files are generated:
```bash
flutter gen-l10n
```

2. Verify `pubspec.yaml` has:
```yaml
flutter:
  generate: true
```

3. Check that `l10n.yaml` exists and is configured correctly.

---

### 4. **Missing Network Security Config File**

**Problem:** `AndroidManifest.xml` references `@xml/network_security_config` but file might be missing or misconfigured.

**Check:**
- File exists at: `android/app/src/main/res/xml/network_security_config.xml`
- Content allows necessary network connections

---

### 5. **Uninitialized Cubit/Bloc Dependencies**

**Problem:** Cubits in `MultiBlocProvider` might depend on services that aren't initialized.

**Current Code:**
```dart
BlocProvider(
  create: (context) => AuthCubit(), // Might need StorageService
),
```

**Solution:** Ensure cubits can be created without external dependencies, or inject dependencies:
```dart
final storageService = StorageService();
await storageService.init();

BlocProvider(
  create: (context) => AuthCubit(storageService: storageService),
),
```

---

### 6. **Missing Permissions for Android 13+**

**Problem:** Android 13+ requires explicit permission requests for media files, notifications, etc.

**Current Permissions:**
- ✅ INTERNET
- ✅ CAMERA (optional)
- ⚠️ Missing: POST_NOTIFICATIONS (Android 13+)
- ⚠️ Missing: READ_MEDIA_IMAGES (Android 13+)

**Solution:** Add to `AndroidManifest.xml`:
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" android:required="false"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" android:required="false"/>
```

---

### 7. **Android API Level Too Low on Device**

**Problem:** Your phone's Android version might be lower than `minSdkVersion`.

**Check:**
- `android/app/build.gradle.kts`: `minSdk = flutter.minSdkVersion`
- Flutter default is usually 21 (Android 5.0)

**Solution:** Lower `minSdk` if needed, or update phone's Android version.

---

### 8. **Native Library Issues**

**Problem:** Some Flutter plugins require native libraries that might not be included.

**Common Plugins with Native Dependencies:**
- `flutter_secure_storage`
- `file_picker`
- `image_picker`
- `flutter_local_notifications`

**Solution:** Ensure all plugins are properly configured in:
- `android/settings.gradle.kts`
- `android/app/build.gradle.kts`

---

### 9. **Missing Assets or Resources**

**Problem:** Release builds might exclude assets that are needed at runtime.

**Check:**
- `pubspec.yaml` assets are declared
- Images, fonts, or other resources exist

**Solution:** Verify `pubspec.yaml`:
```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

---

### 10. **Empty or Invalid API Base URL**

**Problem:** `AppConfig.baseUrl` might be empty or invalid in production build.

**Check:** `EnvironmentConfig.baseUrl` returns valid URL:
```dart
// In production, should return non-empty URL
static String get baseUrl {
  switch (environment) {
    case AppEnvironment.production:
      return 'https://api.scp-platform.com/api/v1';
    // ...
  }
}
```

---

## How to Debug

### 1. **Check Logcat Logs**
```bash
adb logcat | grep -i "flutter\|androidruntime\|crash"
```

### 2. **Build with Debug Symbols**
```bash
flutter build apk --release --split-debug-info=debug-info/
```

### 3. **Test Release Build Locally First**
```bash
flutter install --release
```

### 4. **Enable Verbose Logging**
Add to `main()`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Enable verbose logging in debug
  if (kDebugMode) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      print('Error: ${details.exception}');
      print('Stack: ${details.stack}');
    };
  }
  
  // ... rest of initialization
}
```

### 5. **Use Crashlytics (If Configured)**
If Firebase Crashlytics is set up, check crash reports in Firebase Console.

---

## Recommended Fixes (Priority Order)

### **IMMEDIATE FIXES:**

1. ✅ **Add error handling to `main()` function**
2. ✅ **Add ProGuard rules for model classes**
3. ✅ **Verify localization files are generated**
4. ✅ **Add missing Android 13+ permissions**

### **VERIFICATION:**

1. Build APK locally and test:
   ```bash
   flutter build apk --release
   flutter install --release
   ```

2. Check for warnings during build:
   ```bash
   flutter build apk --release --verbose
   ```

3. Test on multiple Android versions if possible

---

## Most Likely Causes (Based on Code Review)

Based on the code structure, **most likely causes** are:

1. **#1 - Missing Error Handling** (90% probability)
   - `StorageService.init()` might fail in release builds
   - No error handling = silent crash

2. **#3 - Missing Localization Files** (70% probability)
   - `generated/l10n/app_localizations.dart` might not exist in release

3. **#2 - ProGuard Issues** (60% probability)
   - Model classes might be removed by R8

4. **#5 - Uninitialized Dependencies** (40% probability)
   - Cubits might need initialized services

---

## Quick Fix Template

Add this to both `main.dart` files:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
    }
  };
  
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      print('Platform Error: $error');
    }
    return true;
  };
  
  try {
    AppConfig.initialize();
    
    final storageService = StorageService();
    await storageService.init();
    
    runApp(const SCPConsumerApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Fatal Error during initialization: $e');
      print('Stack trace: $stackTrace');
    }
    // In production, you might want to show an error screen
    runApp(const ErrorApp());
  }
}
```

