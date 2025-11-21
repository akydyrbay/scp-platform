/// Environment configuration
/// Supports: development, staging, production
import 'package:flutter/foundation.dart';

enum AppEnvironment {
  development,
  staging,
  production,
}

/// Environment configuration manager
class EnvironmentConfig {
  // Default to development so local runs talk to the local backend by default.
  static AppEnvironment _environment = AppEnvironment.development;
  static bool _initialized = false;

  /// Initialize environment from build-time constants
  /// Usage: flutter run --dart-define=ENV=development
  static void initialize() {
    if (_initialized) return;

    // Default ENV to "development" so local runs (without dart-define) use localhost:3000.
    const env = String.fromEnvironment('ENV', defaultValue: 'development');
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
  /// Priority: 1) API_BASE_URL dart-define 2) If running on web and host is localhost, use local backend 3) environment-based defaults
  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE_URL', defaultValue: '');
    if (override.isNotEmpty) return override;

    // When running in the browser during local development, prefer a localhost backend
    // to avoid CORS/network issues against the production API. Developers can still
    // override with --dart-define=API_BASE_URL if needed.
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1') {
        // default local backend port used by the backend in this repo is 3000
        return 'http://localhost:3000/api/v1';
      }
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

