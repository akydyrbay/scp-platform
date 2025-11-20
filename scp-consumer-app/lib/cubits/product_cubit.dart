import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/product_model.dart';
import 'package:scp_mobile_shared/services/product_service.dart';

/// Product State
class ProductState extends Equatable {
  const ProductState({
    this.products = const [],
    this.selectedProduct,
    this.categories = const [],
    this.isLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedSupplierId,
  });

  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final List<String> categories;
  final bool isLoading;
  final String? error;
  final String searchQuery;
  final String? selectedSupplierId;

  ProductState copyWith({
    List<ProductModel>? products,
    ProductModel? selectedProduct,
    List<String>? categories,
    bool? isLoading,
    String? error,
    String? searchQuery,
    String? selectedSupplierId,
  }) {
    return ProductState(
      products: products ?? this.products,
      selectedProduct: selectedProduct,
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedSupplierId: selectedSupplierId ?? this.selectedSupplierId,
    );
  }

  @override
  List<Object?> get props => [
        products,
        selectedProduct,
        categories,
        isLoading,
        error,
        searchQuery,
        selectedSupplierId,
      ];
}

/// Product Cubit
class ProductCubit extends Cubit<ProductState> {
  final ProductService _productService;

  ProductCubit({ProductService? productService})
      : _productService = productService ?? ProductService(),
        super(const ProductState());

  /// Load products
  Future<void> loadProducts({String? supplierId, String? searchQuery}) async {
    print('🔄 [PRODUCT_CUBIT] Loading products...');
    print('🔄 [PRODUCT_CUBIT] Supplier ID: $supplierId');
    print('🔄 [PRODUCT_CUBIT] Search Query: $searchQuery');
    
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final products = await _productService.getProducts(
        supplierId: supplierId,
        searchQuery: searchQuery,
      );
      
      print('═══════════════════════════════════════');
      print('✅ [PRODUCT_CUBIT] Loaded ${products.length} products');
      if (products.isNotEmpty) {
        print('✅ [PRODUCT_CUBIT] First product: ${products.first.name} (${products.first.id})');
      } else {
        print('⚠️  [PRODUCT_CUBIT] No products returned - consumer may not have approved supplier links');
        print('⚠️  [PRODUCT_CUBIT] Check if user has approved links in consumer_links table');
      }
      print('═══════════════════════════════════════');
      
      // Create new state with products - create new list instance to ensure Equatable detects change
      final productsList = List<ProductModel>.from(products); // New list instance
      
      final newState = state.copyWith(
        products: productsList, // Explicitly set (even if empty) to trigger state change
        isLoading: false,
        searchQuery: searchQuery ?? '',
        selectedSupplierId: supplierId,
      );
      
      print('🔄 [PRODUCT_CUBIT] Emitting new state with ${newState.products.length} products');
      print('🔄 [PRODUCT_CUBIT] State products length: ${newState.products.length}');
      print('🔄 [PRODUCT_CUBIT] State isLoading: ${newState.isLoading}');
      print('🔄 [PRODUCT_CUBIT] State error: ${newState.error}');
      
      emit(newState);
    } catch (e, stackTrace) {
      print('❌ [PRODUCT_CUBIT] Error loading products: $e');
      print('❌ [PRODUCT_CUBIT] Stack trace: $stackTrace');
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Load product details
  Future<void> loadProductDetails(String productId) async {
    emit(state.copyWith(isLoading: true, error: null));

    try {
      final product = await _productService.getProductDetails(productId);
      emit(state.copyWith(
        selectedProduct: product,
        isLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: e.toString(),
      ));
    }
  }

  /// Load categories
  Future<void> loadCategories() async {
    try {
      final categories = await _productService.getCategories();
      emit(state.copyWith(categories: categories));
    } catch (e) {
      // Handle error silently
    }
  }

  /// Search products
  Future<void> searchProducts(String query) async {
    await loadProducts(searchQuery: query);
  }

  /// Clear selected product
  void clearSelectedProduct() {
    emit(state.copyWith(selectedProduct: null));
  }
}

