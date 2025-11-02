/// Application configuration constants
class AppConfig {
  // API Configuration
  static const String baseUrl = 'https://api.scp-platform.com/api/v1';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  
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

