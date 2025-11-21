import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:scp_mobile_shared/models/product_model.dart';
import 'package:scp_mobile_shared/services/storage_service.dart';
import 'package:scp_mobile_shared/config/app_config.dart';

/// Cart State
class CartState extends Equatable {
  const CartState({
    this.items = const {},
    this.supplierGroups = const {},
  });

  final Map<String, CartItem> items; // productId -> CartItem
  final Map<String, List<String>> supplierGroups; // supplierId -> [productIds]

  double get total {
    return items.values.fold(0.0, (sum, item) => sum + item.subtotal);
  }

  int get itemCount {
    return items.values.fold(0, (sum, item) => sum + item.quantity);
  }

  CartState copyWith({
    Map<String, CartItem>? items,
    Map<String, List<String>>? supplierGroups,
  }) {
    return CartState(
      items: items ?? this.items,
      supplierGroups: supplierGroups ?? this.supplierGroups,
    );
  }

  @override
  List<Object?> get props => [items, supplierGroups];
}

/// Cart Cubit
class CartCubit extends Cubit<CartState> {
  CartCubit({StorageService? storageService})
      : _storageService = storageService ?? StorageService(),
        super(const CartState());

  static const String _cartStorageKey = 'consumer_cart_state';
  final StorageService _storageService;

  /// Initialize cart from persisted storage
  Future<void> loadCart() async {
    try {
      final stored = _storageService.getString(_cartStorageKey);
      print('🛒 [CART] loadCart called');
      if (stored == null || stored.isEmpty) {
        print('🛒 [CART] No stored cart found');
        return;
      }

      final decoded = json.decode(stored) as Map<String, dynamic>;
      final itemsJson = decoded['items'] as Map<String, dynamic>? ?? {};
      final groupsJson = decoded['supplierGroups'] as Map<String, dynamic>? ?? {};

      final Map<String, CartItem> items = {};
      itemsJson.forEach((key, value) {
        items[key] = CartItem.fromJson(value as Map<String, dynamic>);
      });

      final Map<String, List<String>> supplierGroups = {};
      groupsJson.forEach((key, value) {
        supplierGroups[key] =
            (value as List<dynamic>).map((e) => e as String).toList();
      });

      final newState = CartState(
        items: items,
        supplierGroups: supplierGroups,
      );
      print(
          '🛒 [CART] Cart loaded from storage. Items: ${newState.items.length}, total: ${newState.total}');
      emit(newState);
    } catch (e) {
      print('❌ [CART] Failed to load cart from storage: $e');
    }
  }

  Future<void> _persistCart(CartState state) async {
    try {
      final itemsJson = <String, dynamic>{};
      state.items.forEach((key, value) {
        itemsJson[key] = value.toJson();
      });

      final data = {
        'items': itemsJson,
        'supplierGroups': state.supplierGroups,
      };

      final encoded = json.encode(data);
      await _storageService.saveString(_cartStorageKey, encoded);
      print(
          '💾 [CART] Cart persisted. Items: ${state.items.length}, total: ${state.total}');
    } catch (e) {
      print('❌ [CART] Failed to persist cart: $e');
    }
  }

  /// Add item to cart
  void addToCart(ProductModel product, {int quantity = 1}) {
    print(
        '🛒 [CART] addToCart called for product=${product.id}, qty=$quantity');
    final Map<String, CartItem> updatedItems = Map.from(state.items);
    final Map<String, List<String>> updatedGroups =
        Map.from(state.supplierGroups);

    if (updatedItems.containsKey(product.id)) {
      // Update existing item
      final existingItem = updatedItems[product.id]!;
      updatedItems[product.id] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
    } else {
      // Add new item
      updatedItems[product.id] = CartItem(
        id: product.id,
        product: product,
        quantity: quantity,
      );

      // Add to supplier group
      if (!updatedGroups.containsKey(product.supplierId)) {
        updatedGroups[product.supplierId] = [];
      }
      updatedGroups[product.supplierId]!.add(product.id);
    }

    final newState = state.copyWith(
      items: updatedItems,
      supplierGroups: updatedGroups,
    );
    emit(newState);
    _persistCart(newState);
  }

  /// Remove item from cart
  void removeFromCart(String productId) {
    print('🛒 [CART] removeFromCart called for product=$productId');
    final Map<String, CartItem> updatedItems = Map.from(state.items);
    final Map<String, List<String>> updatedGroups =
        Map.from(state.supplierGroups);

    final removedItem = updatedItems[productId];
    if (removedItem != null) {
      // Remove from items
      updatedItems.remove(productId);

      // Remove from supplier group
      final supplierId = removedItem.product.supplierId;
      if (updatedGroups.containsKey(supplierId)) {
        updatedGroups[supplierId]!.remove(productId);
        if (updatedGroups[supplierId]!.isEmpty) {
          updatedGroups.remove(supplierId);
        }
      }
    }

    final newState = state.copyWith(
      items: updatedItems,
      supplierGroups: updatedGroups,
    );
    emit(newState);
    _persistCart(newState);
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    print(
        '🛒 [CART] updateQuantity called for product=$productId, qty=$quantity');
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final Map<String, CartItem> updatedItems = Map.from(state.items);
    if (updatedItems.containsKey(productId)) {
      final existingItem = updatedItems[productId]!;
      updatedItems[productId] = existingItem.copyWith(quantity: quantity);
    }

    final newState = state.copyWith(items: updatedItems);
    emit(newState);
    _persistCart(newState);
  }

  /// Clear cart
  void clearCart() {
    print('🛒 [CART] clearCart called');
    const newState = CartState();
    emit(newState);
    _persistCart(newState);
  }

  /// Get items by supplier
  Map<String, List<CartItem>> getItemsBySupplier() {
    final Map<String, List<CartItem>> grouped = {};
    for (final entry in state.supplierGroups.entries) {
      grouped[entry.key] = entry.value
          .map((productId) => state.items[productId]!)
          .toList();
    }
    return grouped;
  }
}

