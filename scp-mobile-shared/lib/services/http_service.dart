import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import '../config/app_config.dart';
import '../services/storage_service.dart';

/// HTTP service for API communication
class HttpService {
  late final Dio _dio;
  final StorageService _storageService = StorageService();
  bool _isRefreshing = false;
  final List<_PendingRequest> _pendingRequests = [];

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
          
          // Handle 401 unauthorized - try to refresh token
          if (error.response?.statusCode == 401) {
            final requestPath = error.requestOptions.path;
            
            // Don't retry refresh endpoint if it fails
            if (requestPath.contains('/auth/refresh')) {
              print('🔐 [HTTP] Refresh token failed - clearing auth tokens');
              await _storageService.clearAuthToken();
              _isRefreshing = false;
              _rejectPendingRequests(error);
              return handler.next(error);
            }
            
            // Try to refresh token
            if (!_isRefreshing) {
              _isRefreshing = true;
              print('🔄 [HTTP] Attempting to refresh token...');
              
              try {
                final refreshToken = await _storageService.getRefreshToken();
                if (refreshToken == null) {
                  print('⚠️  [HTTP] No refresh token available - clearing auth tokens');
                  await _storageService.clearAuthToken();
                  _isRefreshing = false;
                  _rejectPendingRequests(error);
                  return handler.next(error);
                }
                
                // Call refresh endpoint (without auth token since it's public)
                final refreshDio = Dio(
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
                final refreshResponse = await refreshDio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                
                final newAccessToken = refreshResponse.data['access_token'] as String;
                await _storageService.saveAuthToken(newAccessToken);
                print('✅ [HTTP] Token refreshed successfully');
                
                // Retry all pending requests with new token
                _isRefreshing = false;
                await _retryPendingRequests();
                
                // Retry the current request
                final opts = error.requestOptions;
                opts.headers['Authorization'] = 'Bearer $newAccessToken';
                final response = await _dio.request(
                  opts.path,
                  options: Options(
                    method: opts.method,
                    headers: opts.headers,
                  ),
                  data: opts.data,
                  queryParameters: opts.queryParameters,
                );
                return handler.resolve(response);
              } catch (e) {
                print('❌ [HTTP] Token refresh failed: $e');
                await _storageService.clearAuthToken();
                _isRefreshing = false;
                _rejectPendingRequests(error);
                return handler.next(error);
              }
            } else {
              // Already refreshing, queue this request
              print('⏳ [HTTP] Token refresh in progress - queueing request');
              final completer = Completer<Response>();
              _pendingRequests.add(_PendingRequest(
                requestOptions: error.requestOptions,
                completer: completer,
              ));
              
              try {
                final response = await completer.future;
                return handler.resolve(response);
              } catch (e) {
                return handler.next(error);
              }
            }
          }
          
          return handler.next(error);
        },
      ),
    );
  }
  
  Future<void> _retryPendingRequests() async {
    final newToken = await _storageService.getAuthToken();
    if (newToken == null) return;
    
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    
    for (final pending in requests) {
      try {
        final opts = pending.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        final response = await _dio.request(
          opts.path,
          options: Options(
            method: opts.method,
            headers: opts.headers,
          ),
          data: opts.data,
          queryParameters: opts.queryParameters,
        );
        pending.completer.complete(response);
      } catch (e) {
        pending.completer.completeError(e);
      }
    }
  }
  
  void _rejectPendingRequests(DioException error) {
    final requests = List<_PendingRequest>.from(_pendingRequests);
    _pendingRequests.clear();
    
    for (final pending in requests) {
      pending.completer.completeError(error);
    }
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
      // Get file name from path
      final fileName = file.path.split('/').last;
      
      // Create multipart file with proper filename
      final multipartFile = await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      );

      // Build form data
      final formDataMap = <String, dynamic>{
        'file': multipartFile,
      };
      
      // Add additional data if provided
      if (additionalData != null) {
        formDataMap.addAll(additionalData);
      }

      final formData = FormData.fromMap(formDataMap);

      // Log for debugging
      print('📤 [HTTP] Uploading file: $fileName to $path');
      print('📤 [HTTP] Form data keys: ${formDataMap.keys.toList()}');

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
        onSendProgress: onSendProgress,
      );
      
      print('✅ [HTTP] File upload successful: ${response.statusCode}');
      return response;
    } on DioException catch (e) {
      print('❌ [HTTP] File upload failed: ${e.message}');
      if (e.response != null) {
        print('❌ [HTTP] Response: ${e.response?.data}');
      }
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
      final data = error.response?.data;
      String message;
      if (data is Map<String, dynamic>) {
        if (data['message'] is String) {
          message = data['message'] as String;
        } else if (data['error'] is Map &&
            (data['error'] as Map)['message'] is String) {
          // Handle wrapped error objects like: { error: { message: '...' }, success: false }
          message = (data['error'] as Map)['message'] as String;
        } else {
          message = 'An error occurred: ${error.response?.statusCode}';
        }
      } else {
        message = 'An error occurred: ${error.response?.statusCode}';
      }
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

/// Helper class for pending requests during token refresh
class _PendingRequest {
  final RequestOptions requestOptions;
  final Completer<Response> completer;
  
  _PendingRequest({
    required this.requestOptions,
    required this.completer,
  });
}

