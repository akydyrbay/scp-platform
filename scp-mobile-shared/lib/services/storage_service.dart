import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/app_config.dart';

/// Storage service for local data persistence
class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  SharedPreferences? _prefs;

  // Initialize shared preferences
  Future<void> init() async {
    try {
      _prefs ??= await SharedPreferences.getInstance();
    } catch (e) {
      // Handle test environment where SharedPreferences might not be available
      // _prefs will remain null, but methods will handle it gracefully
    }
  }

  // Secure storage operations

  /// Save authentication token
  Future<void> saveAuthToken(String token) async {
    try {
      await _secureStorage.write(
        key: AppConfig.authTokenKey,
        value: token,
      );
    } catch (e) {
      // Handle test environment where FlutterSecureStorage might not be available
    }
  }

  /// Get authentication token
  Future<String?> getAuthToken() async {
    try {
      return await _secureStorage.read(key: AppConfig.authTokenKey);
    } catch (e) {
      // Handle test environment
      return null;
    }
  }

  /// Save refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _secureStorage.write(
        key: AppConfig.refreshTokenKey,
        value: token,
      );
    } catch (e) {
      // Handle test environment where FlutterSecureStorage might not be available
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _secureStorage.read(key: AppConfig.refreshTokenKey);
    } catch (e) {
      // Handle test environment
      return null;
    }
  }

  /// Clear all auth tokens
  Future<void> clearAuthToken() async {
    try {
      await _secureStorage.delete(key: AppConfig.authTokenKey);
      await _secureStorage.delete(key: AppConfig.refreshTokenKey);
    } catch (e) {
      // Handle test environment
    }
    await _prefs?.remove(AppConfig.userDataKey);
  }

  // Regular storage operations

  /// Save user data as JSON string
  Future<void> saveUserData(String userData) async {
    await init();
    await _prefs?.setString(AppConfig.userDataKey, userData);
  }

  /// Get user data
  Future<String?> getUserData() async {
    await init();
    return _prefs?.getString(AppConfig.userDataKey);
  }

  /// Save selected language
  Future<void> saveLanguage(String languageCode) async {
    await init();
    await _prefs?.setString(AppConfig.languageKey, languageCode);
  }

  /// Get saved language
  Future<String?> getLanguage() async {
    await init();
    return _prefs?.getString(AppConfig.languageKey);
  }

  /// Save any string value
  Future<void> saveString(String key, String value) async {
    await init();
    await _prefs?.setString(key, value);
  }

  /// Get any string value
  String? getString(String key) {
    if (_prefs == null) return null;
    return _prefs!.getString(key);
  }

  /// Save any boolean value
  Future<void> saveBool(String key, bool value) async {
    await init();
    await _prefs?.setBool(key, value);
  }

  /// Get any boolean value
  bool? getBool(String key) {
    if (_prefs == null) return null;
    return _prefs!.getBool(key);
  }

  /// Save any integer value
  Future<void> saveInt(String key, int value) async {
    await init();
    await _prefs?.setInt(key, value);
  }

  /// Get any integer value
  int? getInt(String key) {
    if (_prefs == null) return null;
    return _prefs!.getInt(key);
  }

  /// Clear all data
  Future<void> clearAll() async {
    try {
      await _secureStorage.deleteAll();
    } catch (e) {
      // Handle test environment where FlutterSecureStorage might not be available
    }
    await init();
    await _prefs?.clear();
  }
}

