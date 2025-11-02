import '../models/supplier_model.dart';
import '../services/http_service.dart';

/// Supplier service for discovery and linking
class SupplierService {
  final HttpService _httpService;

  SupplierService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Discover/search suppliers
  Future<List<SupplierModel>> discoverSuppliers({
    String? searchQuery,
    int page = 1,
    int pageSize = 20,
    List<String>? categories,
  }) async {
    try {
      final response = await _httpService.get(
        '/suppliers/discover',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
        },
      );

      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data.map((e) => SupplierModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to discover suppliers: $e');
    }
  }

  /// Get supplier details
  Future<SupplierModel> getSupplierDetails(String supplierId) async {
    try {
      final response = await _httpService.get('/suppliers/$supplierId');
      return SupplierModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get supplier details: $e');
    }
  }

  /// Send link request to supplier
  Future<LinkRequest> sendLinkRequest(
    String supplierId, {
    String? message,
  }) async {
    try {
      final response = await _httpService.post(
        '/suppliers/$supplierId/link-request',
        data: {
          if (message != null) 'message': message,
        },
      );

      return LinkRequest.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to send link request: $e');
    }
  }

  /// Get all link requests
  Future<List<LinkRequest>> getLinkRequests({LinkRequestStatus? status}) async {
    try {
      final response = await _httpService.get(
        '/consumer/link-requests',
        queryParameters: {
          if (status != null) 'status': status.name,
        },
      );

      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data.map((e) => LinkRequest.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get link requests: $e');
    }
  }

  /// Get linked suppliers
  Future<List<SupplierModel>> getLinkedSuppliers() async {
    try {
      final response = await _httpService.get('/consumer/linked-suppliers');
      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data.map((e) => SupplierModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get linked suppliers: $e');
    }
  }

  /// Cancel link request
  Future<void> cancelLinkRequest(String requestId) async {
    try {
      await _httpService.delete('/consumer/link-requests/$requestId');
    } catch (e) {
      throw Exception('Failed to cancel link request: $e');
    }
  }
}

