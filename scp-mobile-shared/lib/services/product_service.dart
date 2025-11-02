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

      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data.map((e) => ProductModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get products: $e');
    }
  }

  /// Get product details
  Future<ProductModel> getProductDetails(String productId) async {
    try {
      final response = await _httpService.get('/consumer/products/$productId');
      return ProductModel.fromJson(response.data as Map<String, dynamic>);
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

