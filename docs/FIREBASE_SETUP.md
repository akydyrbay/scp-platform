# Firebase Setup Guide

This guide explains how to set up Firebase for crash reporting, analytics, and push notifications.

## Prerequisites

- Firebase account
- FlutterFire CLI installed
- Android and iOS projects configured

## Installation

### 1. Install FlutterFire CLI

```bash
dart pub global activate flutterfire_cli
```

### 2. Configure Firebase Projects

Run the following command from the project root:

```bash
# For Consumer App
cd scp-consumer-app
flutterfire configure --project=your-consumer-firebase-project

# For Supplier App
cd ../scp-supplier-sales-app
flutterfire configure --project=your-supplier-firebase-project
```

This will:
- Create/update `firebase_options.dart` files
- Configure Android and iOS projects
- Set up necessary configuration files

### 3. Add Dependencies

**For scp-mobile-shared/pubspec.yaml:**
```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_crashlytics: ^3.4.9
  firebase_analytics: ^10.7.4
  firebase_messaging: ^14.7.9
```

**For both app pubspec.yaml files:**
```yaml
dependencies:
  firebase_core: ^2.24.2
```

### 4. Initialize Firebase

Update `lib/main.dart` in both apps:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize app configuration
  AppConfig.initialize();
  
  // ... rest of initialization
  runApp(const SCPConsumerApp());
}
```

### 5. Set Up Crashlytics

**In scp-mobile-shared/lib/services/analytics_service.dart:**
```dart
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class AnalyticsService {
  static void recordError(dynamic error, StackTrace stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace);
  }
  
  static void log(String message) {
    FirebaseCrashlytics.instance.log(message);
  }
}
```

**Error Handling:**
Wrap critical code sections:
```dart
try {
  // Your code
} catch (e, stackTrace) {
  AnalyticsService.recordError(e, stackTrace);
  rethrow;
}
```

### 6. Set Up Analytics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  
  static Future<void> logEvent(String name, Map<String, dynamic>? parameters) {
    return _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }
  
  static Future<void> logLogin(String loginMethod) {
    return _analytics.logLogin(loginMethod: loginMethod);
  }
  
  static Future<void> setUserId(String userId) {
    return _analytics.setUserId(id: userId);
  }
}
```

### 7. Configure Push Notifications (FCM)

**Android Setup:**
1. Add to `AndroidManifest.xml`:
```xml
<service
    android:name="com.google.firebase.messaging.FirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

2. Download `google-services.json` from Firebase Console
3. Place in `android/app/`

**iOS Setup:**
1. Download `GoogleService-Info.plist` from Firebase Console
2. Place in `ios/Runner/`
3. Enable Push Notifications capability in Xcode
4. Upload APNs certificate to Firebase

**Implementation:**
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    
    // Get FCM token
    String? token = await FirebaseMessaging.instance.getToken();
    print('FCM Token: $token');
    // Send token to your backend
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // Handle message
    });
    
    // Handle background messages (requires top-level function)
  }
}
```

### 8. Background Message Handler

Create `firebase_messaging_handler.dart`:
```dart
import 'package:firebase_messaging/firebase_messaging.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background message
}
```

Register in `main.dart`:
```dart
FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
```

## Testing

### Test Crashlytics
```dart
FirebaseCrashlytics.instance.crash(); // Force a crash for testing
```

### Test Analytics
Check Firebase Console → Analytics → Events

### Test FCM
Use Firebase Console → Cloud Messaging to send test messages

## Production Checklist

- [ ] Firebase projects created for both apps
- [ ] `google-services.json` added to Android projects
- [ ] `GoogleService-Info.plist` added to iOS projects
- [ ] Firebase initialized in main.dart
- [ ] Crashlytics configured
- [ ] Analytics events logged
- [ ] FCM tokens sent to backend
- [ ] Background message handler registered
- [ ] APNs certificate uploaded (iOS)
- [ ] Tested on physical devices

## Additional Resources

- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Firebase Console](https://console.firebase.google.com/)
- [Firebase Crashlytics](https://firebase.google.com/docs/crashlytics)
- [Firebase Analytics](https://firebase.google.com/docs/analytics)
- [Firebase Cloud Messaging](https://firebase.google.com/docs/cloud-messaging)

---

**Note**: This is a setup guide. Actual implementation requires Firebase projects to be created first.

