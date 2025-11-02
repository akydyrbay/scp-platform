import 'package:flutter_test/flutter_test.dart';
import 'package:scp_mobile_shared/services/storage_service.dart';
import 'package:scp_mobile_shared/config/app_config.dart';

void main() {
  group('StorageService', () {
    late StorageService storageService;

    setUp(() {
      storageService = StorageService();
    });

    tearDown(() async {
      await storageService.clearAll();
    });

    test('should initialize successfully', () async {
      await storageService.init();
      expect(true, isTrue); // If no exception, init succeeded
    });

    test('should save and retrieve auth token', () async {
      await storageService.init();
      const testToken = 'test_auth_token_123';

      await storageService.saveAuthToken(testToken);
      final retrievedToken = await storageService.getAuthToken();

      expect(retrievedToken, equals(testToken));
    });

    test('should save and retrieve refresh token', () async {
      await storageService.init();
      const testToken = 'test_refresh_token_456';

      await storageService.saveRefreshToken(testToken);
      final retrievedToken = await storageService.getRefreshToken();

      expect(retrievedToken, equals(testToken));
    });

    test('should clear auth tokens', () async {
      await storageService.init();
      await storageService.saveAuthToken('test_token');
      await storageService.saveRefreshToken('test_refresh');

      await storageService.clearAuthToken();

      final authToken = await storageService.getAuthToken();
      final refreshToken = await storageService.getRefreshToken();

      expect(authToken, isNull);
      expect(refreshToken, isNull);
    });

    test('should save and retrieve user data', () async {
      await storageService.init();
      const testUserData = '{"id":"123","email":"test@example.com"}';

      await storageService.saveUserData(testUserData);
      final retrievedData = await storageService.getUserData();

      expect(retrievedData, equals(testUserData));
    });

    test('should save and retrieve language preference', () async {
      await storageService.init();
      const testLanguage = 'en';

      await storageService.saveLanguage(testLanguage);
      final retrievedLanguage = await storageService.getLanguage();

      expect(retrievedLanguage, equals(testLanguage));
    });

    test('should save and retrieve string values', () async {
      await storageService.init();
      const testKey = 'test_key';
      const testValue = 'test_value';

      await storageService.saveString(testKey, testValue);
      final retrievedValue = storageService.getString(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should save and retrieve boolean values', () async {
      await storageService.init();
      const testKey = 'bool_key';
      const testValue = true;

      await storageService.saveBool(testKey, testValue);
      final retrievedValue = storageService.getBool(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should save and retrieve integer values', () async {
      await storageService.init();
      const testKey = 'int_key';
      const testValue = 42;

      await storageService.saveInt(testKey, testValue);
      final retrievedValue = storageService.getInt(testKey);

      expect(retrievedValue, equals(testValue));
    });

    test('should clear all data', () async {
      await storageService.init();
      await storageService.saveAuthToken('test_token');
      await storageService.saveString('test_key', 'test_value');

      await storageService.clearAll();

      final token = await storageService.getAuthToken();
      final string = storageService.getString('test_key');

      expect(token, isNull);
      expect(string, isNull);
    });
  });
}

