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
        '/consumer/suppliers',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (searchQuery != null && searchQuery.isNotEmpty) 'search': searchQuery,
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
        },
      );

      // Handle both paginated format (results) and direct format (data)
      final dynamic payload = response.data;
      final List<dynamic> data = (payload is Map && payload['results'] != null)
          ? payload['results'] as List<dynamic>
          : (payload is Map && payload['data'] != null)
              ? payload['data'] as List<dynamic>
              : (payload is List)
                  ? payload
                  : <dynamic>[];
      return data.map((e) => SupplierModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to discover suppliers: $e');
    }
  }

  /// Get supplier details
  Future<SupplierModel> getSupplierDetails(String supplierId) async {
    try {
      final response = await _httpService.get('/suppliers/$supplierId');
      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> supplierData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return SupplierModel.fromJson(supplierData);
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
        '/consumer/suppliers/$supplierId/link-request',
        data: {
          if (message != null) 'message': message,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> linkData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      
      // Convert ConsumerLink format to LinkRequest format
      final Map<String, dynamic> linkRequestData = {
        'id': linkData['id'] as String,
        'supplier_id': linkData['supplier_id'] as String,
        'supplier_name': linkData['supplier'] != null 
            ? (linkData['supplier'] as Map<String, dynamic>)['name'] as String?
            : null,
        'supplier_logo_url': linkData['supplier'] != null 
            ? (linkData['supplier'] as Map<String, dynamic>)['logo_url'] as String?
            : null,
        'status': linkData['status'] as String,
        'message': message,
        'requested_at': linkData['requested_at'] as String,
        'responded_at': linkData['approved_at'] as String?,
      };
      
      return LinkRequest.fromJson(linkRequestData);
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
      // Handle both paginated format (results) and direct format (data)
      final dynamic payload = response.data;
      final List<dynamic> data = (payload is Map && payload['results'] != null)
          ? payload['results'] as List<dynamic>
          : (payload is Map && payload['data'] != null)
              ? payload['data'] as List<dynamic>
              : (payload is List)
                  ? payload
                  : <dynamic>[];
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

