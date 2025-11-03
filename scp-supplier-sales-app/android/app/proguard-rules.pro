# Add project specific ProGuard rules here.

# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Ignore Play Core classes for deferred components (not used)
-dontwarn com.google.android.play.core.splitcompat.**
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**

# Dio
-keep class dio.** { *; }
-dontwarn dio.**

# Flutter Secure Storage
-keep class androidx.security.crypto.** { *; }
-dontwarn androidx.security.crypto.**
-keep class androidx.biometric.** { *; }
-dontwarn androidx.biometric.**

# Shared Preferences
-keep class androidx.preference.** { *; }
-dontwarn androidx.preference.**

# Local Notifications
-keep class androidx.core.app.** { *; }
-dontwarn androidx.core.app.**

# Socket.io
-keep class io.socket.** { *; }
-dontwarn io.socket.**

# Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep model classes
-keep class com.scp.supplier.** { *; }
-keep class scp_mobile_shared.** { *; }
-dontwarn scp_mobile_shared.**

# Keep Flutter generated files (localization, etc.)
-keep class **.generated.** { *; }
-keep class **.generated.l10n.** { *; }

# Keep attributes needed for JSON serialization
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep data classes used for JSON
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Preserve annotations
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations

# Remove logging
-assumenosideeffects class android.util.Log {
    public static boolean isLoggable(java.lang.String, int);
    public static int v(...);
    public static int i(...);
    public static int w(...);
    public static int d(...);
    public static int e(...);
}

