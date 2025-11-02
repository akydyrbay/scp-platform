import '../models/order_model.dart';
import '../services/http_service.dart';

/// Order service for placing and tracking orders
class OrderService {
  final HttpService _httpService;

  OrderService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Place an order
  Future<OrderModel> placeOrder({
    required String supplierId,
    required List<Map<String, dynamic>> items,
    ShippingAddress? shippingAddress,
    String? notes,
  }) async {
    try {
      final response = await _httpService.post(
        '/consumer/orders',
        data: {
          'supplier_id': supplierId,
          'items': items,
          if (shippingAddress != null)
            'shipping_address': shippingAddress.toJson(),
          if (notes != null) 'notes': notes,
        },
      );

      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to place order: $e');
    }
  }

  /// Get order history
  Future<List<OrderModel>> getOrderHistory({
    OrderStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpService.get(
        '/consumer/orders',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status.name,
        },
      );

      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get order history: $e');
    }
  }

  /// Get order details
  Future<OrderModel> getOrderDetails(String orderId) async {
    try {
      final response = await _httpService.get('/consumer/orders/$orderId');
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get order details: $e');
    }
  }

  /// Get current/active orders
  Future<List<OrderModel>> getCurrentOrders() async {
    try {
      final response = await _httpService.get('/consumer/orders/current');
      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get current orders: $e');
    }
  }

  /// Cancel an order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _httpService.post('/consumer/orders/$orderId/cancel');
    } catch (e) {
      throw Exception('Failed to cancel order: $e');
    }
  }

  /// Track an order
  Future<OrderModel> trackOrder(String orderId) async {
    try {
      final response = await _httpService.get('/consumer/orders/$orderId/track');
      return OrderModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to track order: $e');
    }
  }
}

