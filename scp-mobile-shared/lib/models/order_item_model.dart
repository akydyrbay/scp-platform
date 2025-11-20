import 'package:equatable/equatable.dart';

/// Order item model
class OrderItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? productImageUrl;
  final String unit;
  final double unitPrice;
  final int quantity;
  final double subtotal;

  const OrderItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.unit,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    // Handle product name from nested product object or direct field
    String productName = '';
    if (json['product'] is Map) {
      final product = json['product'] as Map<String, dynamic>;
      productName = (product['name'] as String?) ?? '';
    }
    if (productName.isEmpty) {
      productName = (json['product_name'] as String?) ?? 'Unknown Product';
    }

    // Handle unit from nested product object or direct field
    String unit = '';
    if (json['product'] is Map) {
      final product = json['product'] as Map<String, dynamic>;
      unit = (product['unit'] as String?) ?? '';
    }
    if (unit.isEmpty) {
      unit = (json['unit'] as String?) ?? 'unit';
    }

    // Handle product image URL
    String? productImageUrl;
    if (json['product'] is Map) {
      final product = json['product'] as Map<String, dynamic>;
      productImageUrl = product['image_url'] as String?;
    }
    if (productImageUrl == null) {
      productImageUrl = json['product_image_url'] as String?;
    }

    return OrderItem(
      id: (json['id'] as String?) ?? '',
      productId: (json['product_id'] as String?) ?? '',
      productName: productName,
      productImageUrl: productImageUrl,
      unit: unit,
      unitPrice: ((json['unit_price'] as num?) ?? 0).toDouble(),
      quantity: (json['quantity'] as int?) ?? 0,
      subtotal: ((json['subtotal'] as num?) ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'product_image_url': productImageUrl,
      'unit': unit,
      'unit_price': unitPrice,
      'quantity': quantity,
      'subtotal': subtotal,
    };
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        productImageUrl,
        unit,
        unitPrice,
        quantity,
        subtotal,
      ];
}

