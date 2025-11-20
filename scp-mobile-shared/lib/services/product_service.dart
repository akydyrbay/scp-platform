import '../models/product_model.dart';
import '../services/http_service.dart';

/// Product service for catalog and products
class ProductService {
  final HttpService _httpService;

  ProductService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Get products from linked suppliers
  Future<List<ProductModel>> getProducts({
    String? supplierId,
    String? searchQuery,
    List<String>? categories,
    int page = 1,
    int pageSize = 20,
    String? sortBy,
    bool? inStockOnly,
  }) async {
    try {
      final response = await _httpService.get(
        '/consumer/products',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (supplierId != null && supplierId.isNotEmpty)
            'supplier_id': supplierId,
          if (searchQuery != null && searchQuery.isNotEmpty)
            'search': searchQuery,
          if (categories != null && categories.isNotEmpty)
            'categories': categories.join(','),
          if (sortBy != null) 'sort_by': sortBy,
          if (inStockOnly != null) 'in_stock_only': inStockOnly,
        },
      );

      // Handle both paginated format (results) and direct format (data)
      final dynamic payload = response.data;
      
      // Log response for debugging
      print('═══════════════════════════════════════');
      print('📦 [PRODUCTS] API Response received');
      print('📦 [PRODUCTS] Status Code: ${response.statusCode}');
      print('📦 [PRODUCTS] Payload type: ${payload.runtimeType}');
      print('📦 [PRODUCTS] Full payload: $payload');
      print('═══════════════════════════════════════');
      
      List<dynamic> data;
      if (payload is Map) {
        print('📦 [PRODUCTS] Payload is Map with keys: ${payload.keys.toList()}');
        if (payload['results'] != null) {
          data = payload['results'] as List<dynamic>;
          print('📦 [PRODUCTS] Found ${data.length} products in results field');
          if (data.isEmpty) {
            print('⚠️  [PRODUCTS] Results array is empty - checking pagination info');
            if (payload['pagination'] != null) {
              print('📦 [PRODUCTS] Pagination: ${payload['pagination']}');
            }
          }
        } else if (payload['data'] != null) {
          data = payload['data'] as List<dynamic>;
          print('📦 [PRODUCTS] Found ${data.length} products in data field');
        } else {
          print('⚠️  [PRODUCTS] No results or data field in response');
          print('⚠️  [PRODUCTS] Available keys: ${payload.keys.toList()}');
          data = <dynamic>[];
        }
      } else if (payload is List) {
        data = payload;
        print('📦 [PRODUCTS] Direct list response with ${data.length} products');
      } else {
        print('⚠️  [PRODUCTS] Unexpected payload format: ${payload.runtimeType}');
        print('⚠️  [PRODUCTS] Payload value: $payload');
        data = <dynamic>[];
      }

      // Parse products with error handling
      final products = <ProductModel>[];
      for (var item in data) {
        try {
          if (item is Map<String, dynamic>) {
            final product = ProductModel.fromJson(item);
            products.add(product);
          } else {
            print('⚠️  [PRODUCTS] Skipping invalid product item: ${item.runtimeType}');
          }
        } catch (e, stackTrace) {
          print('❌ [PRODUCTS] Failed to parse product: $e');
          print('❌ [PRODUCTS] Item: $item');
          print('❌ [PRODUCTS] Stack: $stackTrace');
          // Continue parsing other products
        }
      }

      print('✅ [PRODUCTS] Successfully parsed ${products.length} products');
      return products;
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get product details
  Future<ProductModel> getProductDetails(String productId) async {
    try {
      final response = await _httpService.get('/consumer/products/$productId');
      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> productData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return ProductModel.fromJson(productData);
    } catch (e) {
      throw Exception('Failed to get product details: $e');
    }
  }

  /// Get product categories
  Future<List<String>> getCategories() async {
    try {
      final response = await _httpService.get('/consumer/products/categories');
      final List<dynamic> data = response.data['categories'] as List<dynamic>;
      return data.map((e) => e as String).toList();
    } catch (e) {
      throw Exception('Failed to get categories: $e');
    }
  }

  /// Search products
  Future<List<ProductModel>> searchProducts(String query) async {
    return getProducts(searchQuery: query);
  }
}

