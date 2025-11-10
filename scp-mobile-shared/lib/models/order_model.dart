import 'package:equatable/equatable.dart';
import 'order_item_model.dart';

/// Order model for tracking and history
class OrderModel extends Equatable {
  final String id;
  final String orderNumber;
  final String supplierId;
  final String supplierName;
  final String? supplierLogoUrl;
  final List<OrderItem> items;
  final double subtotal;
  final double tax;
  final double shippingFee;
  final double total;
  final OrderStatus status;
  final String? notes;
  final DateTime orderDate;
  final DateTime? estimatedDeliveryDate;
  final DateTime? deliveryDate;
  final ShippingAddress? shippingAddress;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.supplierId,
    required this.supplierName,
    this.supplierLogoUrl,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.shippingFee,
    required this.total,
    required this.status,
    this.notes,
    required this.orderDate,
    this.estimatedDeliveryDate,
    this.deliveryDate,
    this.shippingAddress,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final itemsRaw = json['items'];
    final itemsList = (itemsRaw is List)
        ? itemsRaw.map((e) => OrderItem.fromJson(e as Map<String, dynamic>)).toList()
        : <OrderItem>[];

    final orderNumber = (json['order_number'] as String?) ??
        (json['id'] as String).substring(0, 8);
    final supplierName = (json['supplier_name'] as String?) ?? 'Supplier';
    final orderDateStr = (json['order_date'] as String?) ?? (json['created_at'] as String);

    return OrderModel(
      id: json['id'] as String,
      orderNumber: orderNumber,
      supplierId: json['supplier_id'] as String,
      supplierName: supplierName,
      supplierLogoUrl: json['supplier_logo_url'] as String?,
      items: itemsList,
      subtotal: (json['subtotal'] as num).toDouble(),
      tax: (json['tax'] as num).toDouble(),
      shippingFee: (json['shipping_fee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      status: _parseOrderStatus(json['status'] as String),
      notes: json['notes'] as String?,
      orderDate: DateTime.parse(orderDateStr),
      estimatedDeliveryDate: json['estimated_delivery_date'] != null
          ? DateTime.parse(json['estimated_delivery_date'] as String)
          : null,
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'] as String)
          : null,
      shippingAddress: json['shipping_address'] != null
          ? ShippingAddress.fromJson(
              json['shipping_address'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  static OrderStatus _parseOrderStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return OrderStatus.pending;
      case 'confirmed':
        return OrderStatus.confirmed;
      case 'processing':
        return OrderStatus.processing;
      case 'shipped':
        return OrderStatus.shipped;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_logo_url': supplierLogoUrl,
      'items': items.map((e) => e.toJson()).toList(),
      'subtotal': subtotal,
      'tax': tax,
      'shipping_fee': shippingFee,
      'total': total,
      'status': status.name,
      'notes': notes,
      'order_date': orderDate.toIso8601String(),
      'estimated_delivery_date': estimatedDeliveryDate?.toIso8601String(),
      'delivery_date': deliveryDate?.toIso8601String(),
      'shipping_address': shippingAddress?.toJson(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        orderNumber,
        supplierId,
        supplierName,
        supplierLogoUrl,
        items,
        subtotal,
        tax,
        shippingFee,
        total,
        status,
        notes,
        orderDate,
        estimatedDeliveryDate,
        deliveryDate,
        shippingAddress,
      ];
}

/// Order status enum
enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

/// Shipping address model
class ShippingAddress extends Equatable {
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final String? contactName;
  final String? contactPhone;

  const ShippingAddress({
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.contactName,
    this.contactPhone,
  });

  factory ShippingAddress.fromJson(Map<String, dynamic> json) {
    return ShippingAddress(
      street: json['street'] as String,
      city: json['city'] as String,
      state: json['state'] as String,
      postalCode: json['postal_code'] as String,
      country: json['country'] as String,
      contactName: json['contact_name'] as String?,
      contactPhone: json['contact_phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'country': country,
      'contact_name': contactName,
      'contact_phone': contactPhone,
    };
  }

  String get fullAddress {
    return '$street, $city, $state $postalCode, $country';
  }

  @override
  List<Object?> get props => [
        street,
        city,
        state,
        postalCode,
        country,
        contactName,
        contactPhone,
      ];
}

