import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';

/// HTTP service for API communication
class HttpService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();

  HttpService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: AppConfig.connectTimeout,
        receiveTimeout: AppConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Add interceptors for authentication and logging
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Log request for debugging
          print('🌐 [HTTP] ${options.method} ${options.uri}');
          
          // Add auth token to requests
          final token = await _storageService.getAuthToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            print('🔐 [HTTP] Auth token added to request');
          } else {
            print('ℹ️  [HTTP] No auth token - unauthenticated request');
          }
          return handler.next(options);
        },
        onResponse: (response, handler) {
          // Log successful responses
          print('✅ [HTTP] ${response.requestOptions.method} ${response.requestOptions.uri} - Status: ${response.statusCode}');
          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          // Log error before handling
          print('❌ [HTTP] ${error.requestOptions.method} ${error.requestOptions.uri} - Error: ${error.type}');
          
          // Handle 401 unauthorized - logout user
          if (error.response?.statusCode == 401) {
            print('🔐 [HTTP] 401 Unauthorized - clearing auth token');
            await _storageService.clearAuthToken();
            // Navigate to login if needed
          }
          return handler.next(error);
        },
      ),
    );
  }

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request
  Future<Response> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT request
  Future<Response> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE request
  Future<Response> delete(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST request for file upload
  Future<Response> postFile(
    String path,
    File file, {
    Map<String, dynamic>? additionalData,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path),
        ...?additionalData,
      });

      final response = await _dio.post(
        path,
        data: formData,
        onSendProgress: onSendProgress,
      );
      return response;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Handle errors
  String _handleError(DioException error) {
    // Log error for debugging
    print('═══════════════════════════════════════');
    print('❌ [HTTP] ERROR');
    print('═══════════════════════════════════════');
    print('URL: ${error.requestOptions.uri}');
    print('Method: ${error.requestOptions.method}');
    print('Error Type: ${error.type}');
    print('Message: ${error.message}');
    
    if (error.response != null) {
      print('Status Code: ${error.response?.statusCode}');
      print('Response Data: ${error.response?.data}');
      // Server responded with error
      final message = error.response?.data['message'] ??
          'An error occurred: ${error.response?.statusCode}';
      print('Error Message: $message');
      print('═══════════════════════════════════════');
      return message;
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      print('Error: Connection timeout');
      print('═══════════════════════════════════════');
      return 'Connection timeout. Please try again.';
    } else if (error.type == DioExceptionType.unknown) {
      print('Error: Unknown (likely network issue)');
      print('═══════════════════════════════════════');
      return 'No internet connection. Please check your network.';
    } else {
      print('Error: Unexpected error');
      print('═══════════════════════════════════════');
      return 'An unexpected error occurred. Please try again.';
    }
  }
}

