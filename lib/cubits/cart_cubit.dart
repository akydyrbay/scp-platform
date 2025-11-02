import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/product_model.dart';

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
  CartCubit() : super(const CartState());

  /// Add item to cart
  void addToCart(ProductModel product, {int quantity = 1}) {
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

    emit(state.copyWith(
      items: updatedItems,
      supplierGroups: updatedGroups,
    ));
  }

  /// Remove item from cart
  void removeFromCart(String productId) {
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

    emit(state.copyWith(
      items: updatedItems,
      supplierGroups: updatedGroups,
    ));
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final Map<String, CartItem> updatedItems = Map.from(state.items);
    if (updatedItems.containsKey(productId)) {
      final existingItem = updatedItems[productId]!;
      updatedItems[productId] = existingItem.copyWith(quantity: quantity);
    }

    emit(state.copyWith(items: updatedItems));
  }

  /// Clear cart
  void clearCart() {
    emit(const CartState());
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

