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
    return OrderItem(
      id: json['id'] as String,
      productId: json['product_id'] as String,
      productName: json['product_name'] as String,
      productImageUrl: json['product_image_url'] as String?,
      unit: json['unit'] as String,
      unitPrice: (json['unit_price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      subtotal: (json['subtotal'] as num).toDouble(),
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

