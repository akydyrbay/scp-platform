import 'package:equatable/equatable.dart';

/// Product model from supplier catalog
class ProductModel extends Equatable {
  final String id;
  final String name;
  final String? description;
  final String supplierId;
  final String supplierName;
  final String? imageUrl;
  final String unit;
  final double price;
  final int stockQuantity;
  final int minimumOrderQuantity;
  final List<String>? categories;
  final Map<String, dynamic>? specifications;
  final bool isAvailable;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const ProductModel({
    required this.id,
    required this.name,
    this.description,
    required this.supplierId,
    required this.supplierName,
    this.imageUrl,
    required this.unit,
    required this.price,
    required this.stockQuantity,
    required this.minimumOrderQuantity,
    this.categories,
    this.specifications,
    this.isAvailable = true,
    required this.createdAt,
    this.updatedAt,
  });

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      supplierId: json['supplier_id'] as String? ?? '',
      supplierName: json['supplier_name'] as String? ?? 'Supplier',
      imageUrl: json['image_url'] as String?,
      unit: json['unit'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: (json['stock_quantity'] ?? json['stock_level']) as int? ?? 0,
      minimumOrderQuantity: (json['minimum_order_quantity'] ?? json['min_order_quantity']) as int? ?? 1,
      categories: (json['categories'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      specifications: json['specifications'] as Map<String, dynamic>?,
      isAvailable: json['is_available'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'image_url': imageUrl,
      'unit': unit,
      'price': price,
      'stock_quantity': stockQuantity,
      'minimum_order_quantity': minimumOrderQuantity,
      'categories': categories,
      'specifications': specifications,
      'is_available': isAvailable,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        supplierId,
        supplierName,
        imageUrl,
        unit,
        price,
        stockQuantity,
        minimumOrderQuantity,
        categories,
        specifications,
        isAvailable,
        createdAt,
        updatedAt,
      ];
}

/// Cart item model
class CartItem extends Equatable {
  final String id;
  final ProductModel product;
  final int quantity;
  final String? notes;

  const CartItem({
    required this.id,
    required this.product,
    required this.quantity,
    this.notes,
  });

  double get subtotal => product.price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      product: ProductModel.fromJson(json['product'] as Map<String, dynamic>),
      quantity: json['quantity'] as int,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product': product.toJson(),
      'quantity': quantity,
      'notes': notes,
    };
  }

  CartItem copyWith({
    String? id,
    ProductModel? product,
    int? quantity,
    String? notes,
  }) {
    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [id, product, quantity, notes];
}

