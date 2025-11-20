import 'package:scp_mobile_shared/models/order_model.dart';
import 'package:scp_mobile_shared/services/http_service.dart';

/// Interface for supplier order service operations
abstract class SupplierOrderServiceInterface {
  Future<List<OrderModel>> getOrders({int page = 1, int pageSize = 20});
  Future<OrderModel> getOrderDetails(String orderId);
  Future<OrderModel> trackOrder(String orderId);
  Future<OrderModel> placeOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    ShippingAddress? shippingAddress,
    String? notes,
  });
  Future<void> cancelOrder(String orderId);
}

/// Supplier-side order service hitting /supplier endpoints
class SupplierOrderService implements SupplierOrderServiceInterface {
  final HttpService _httpService;

  SupplierOrderService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Get supplier orders (paginated)
  Future<List<OrderModel>> getOrders({
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpService.get(
        '/supplier/orders',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      // Handle null results - backend may return null if no orders exist
      final results = response.data['results'];
      if (results == null) {
        return [];
      }

      // Ensure results is a List
      if (results is! List) {
        return [];
      }

      final List<dynamic> data = results as List<dynamic>;
      return data
          .map((e) => OrderModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get supplier orders: $e');
    }
  }

  /// Get order details by ID (no dedicated endpoint; fetch list and find)
  Future<OrderModel> getOrderDetails(String orderId) async {
    final orders = await getOrders(page: 1, pageSize: 100);
    try {
      return orders.firstWhere((o) => o.id == orderId);
    } catch (_) {
      throw Exception('Order not found');
    }
  }

  /// Track order (reuses getOrderDetails for supplier context)
  Future<OrderModel> trackOrder(String orderId) {
    return getOrderDetails(orderId);
  }

  /// Place order (not supported in supplier app)
  Future<OrderModel> placeOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    ShippingAddress? shippingAddress,
    String? notes,
  }) async {
    throw Exception('Placing orders is not supported for supplier role');
  }

  /// Cancel order (not supported in supplier app)
  Future<void> cancelOrder(String orderId) async {
    throw Exception('Cancelling orders is not supported for supplier role');
  }
}


