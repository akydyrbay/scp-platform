import 'environment.dart';

/// Application configuration constants
class AppConfig {
  // Initialize environment on first access
  static void initialize() {
    EnvironmentConfig.initialize();
  }

  // API Configuration - uses environment-based configuration
  static String get baseUrl => EnvironmentConfig.baseUrl;
  
  // Timeouts - uses environment-based configuration
  static Duration get connectTimeout => EnvironmentConfig.connectTimeout;
  static Duration get receiveTimeout => EnvironmentConfig.receiveTimeout;
  
  // Environment
  static AppEnvironment get environment => EnvironmentConfig.environment;
  static bool get isDevelopment => EnvironmentConfig.isDevelopment;
  static bool get isStaging => EnvironmentConfig.isStaging;
  static bool get isProduction => EnvironmentConfig.isProduction;
  static bool get enableDebugLogging => EnvironmentConfig.enableDebugLogging;
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String languageKey = 'app_language';
  
  // Pagination
  static const int pageSize = 20;
  
  // Other constants
  static const double minTouchTargetSize = 48.0;
  static const int maxImageSizeMB = 5;
}

