import 'dart:convert';
import '../models/user_model.dart';
import '../services/http_service.dart';
import '../services/storage_service.dart';

/// Authentication service
class AuthService {
  final HttpService _httpService;
  final StorageService _storageService;

  AuthService({
    HttpService? httpService,
    StorageService? storageService,
  })  : _httpService = httpService ?? HttpService(),
        _storageService = storageService ?? StorageService();

  /// Login user
  Future<LoginResponse> login(String email, String password, {String role = 'consumer'}) async {
    try {
      final response = await _httpService.post(
        '/auth/login',
        data: {
          'email': email,
          'password': password,
          'role': role,
        },
      );

      final loginResponse = LoginResponse.fromJson(response.data as Map<String, dynamic>);
      
      // Save tokens
      await _storageService.saveAuthToken(loginResponse.accessToken);
      if (loginResponse.refreshToken != null) {
        await _storageService.saveRefreshToken(loginResponse.refreshToken!);
      }

      // Save user data as JSON
      await _storageService.saveUserData(
        json.encode(loginResponse.user.toJson()),
      );

      return loginResponse;
    } catch (e) {
      throw Exception('Login failed: $e');
    }
  }

  /// Logout user
  Future<void> logout() async {
    try {
      await _httpService.post('/auth/logout');
    } catch (e) {
      // Continue even if API call fails
    } finally {
      await _storageService.clearAuthToken();
    }
  }

  /// Get current user
  Future<UserModel?> getCurrentUser() async {
    try {
      final userDataJson = await _storageService.getUserData();
      if (userDataJson == null || userDataJson.isEmpty) {
        return null;
      }
      
      // Parse the JSON string to Map
      final userDataMap = json.decode(userDataJson) as Map<String, dynamic>;
      return UserModel.fromJson(userDataMap);
    } catch (e) {
      return null;
    }
  }

  /// Refresh auth token
  Future<String> refreshToken() async {
    try {
      final refreshToken = await _storageService.getRefreshToken();
      if (refreshToken == null) {
        throw Exception('No refresh token available');
      }

      final response = await _httpService.post(
        '/auth/refresh',
        data: {'refresh_token': refreshToken},
      );

      final newToken = response.data['access_token'] as String;
      await _storageService.saveAuthToken(newToken);

      return newToken;
    } catch (e) {
      await _storageService.clearAuthToken();
      throw Exception('Token refresh failed: $e');
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await _storageService.getAuthToken();
    return token != null;
  }
}

