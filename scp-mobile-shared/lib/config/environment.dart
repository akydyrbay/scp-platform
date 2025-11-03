/// Environment configuration
/// Supports: development, staging, production
enum AppEnvironment {
  development,
  staging,
  production,
}

/// Environment configuration manager
class EnvironmentConfig {
  static AppEnvironment _environment = AppEnvironment.production;
  static bool _initialized = false;

  /// Initialize environment from build-time constants
  /// Usage: flutter run --dart-define=ENV=development
  static void initialize() {
    if (_initialized) return;

    const env = String.fromEnvironment('ENV', defaultValue: 'production');
    _environment = _parseEnvironment(env);
    _initialized = true;
  }

  static AppEnvironment _parseEnvironment(String env) {
    switch (env.toLowerCase()) {
      case 'dev':
      case 'development':
        return AppEnvironment.development;
      case 'staging':
      case 'stage':
        return AppEnvironment.staging;
      case 'prod':
      case 'production':
      default:
        return AppEnvironment.production;
    }
  }

  static AppEnvironment get environment {
    if (!_initialized) {
      initialize();
    }
    return _environment;
  }

  static bool get isDevelopment => environment == AppEnvironment.development;
  static bool get isStaging => environment == AppEnvironment.staging;
  static bool get isProduction => environment == AppEnvironment.production;

  /// Get API base URL based on environment
  static String get baseUrl {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: '',
    );

    if (baseUrl.isNotEmpty) {
      return baseUrl;
    }

    switch (environment) {
      case AppEnvironment.development:
        return 'http://localhost:3000/api/v1';
      case AppEnvironment.staging:
        return 'https://staging-api.scp-platform.com/api/v1';
      case AppEnvironment.production:
        return 'https://api.scp-platform.com/api/v1';
    }
  }

  /// Get API timeout based on environment
  static Duration get connectTimeout {
    switch (environment) {
      case AppEnvironment.development:
        return const Duration(seconds: 60); // More lenient for dev
      case AppEnvironment.staging:
        return const Duration(seconds: 45);
      case AppEnvironment.production:
        return const Duration(seconds: 30);
    }
  }

  /// Get API receive timeout based on environment
  static Duration get receiveTimeout {
    switch (environment) {
      case AppEnvironment.development:
        return const Duration(seconds: 60);
      case AppEnvironment.staging:
        return const Duration(seconds: 45);
      case AppEnvironment.production:
        return const Duration(seconds: 30);
    }
  }

  /// Enable debug logging in development
  static bool get enableDebugLogging => isDevelopment || isStaging;
}

