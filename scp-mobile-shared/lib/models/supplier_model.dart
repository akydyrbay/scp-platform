import 'package:equatable/equatable.dart';

/// Supplier model for discovery and linking
class SupplierModel extends Equatable {
  final String id;
  final String companyName;
  final String? description;
  final String? logoUrl;
  final String? address;
  final String? city;
  final String? country;
  final String? phoneNumber;
  final String? email;
  final double? rating;
  final int? reviewCount;
  final List<String> categories;
  final bool isLinked;
  final LinkRequestStatus? linkStatus;
  final DateTime createdAt;

  const SupplierModel({
    required this.id,
    required this.companyName,
    this.description,
    this.logoUrl,
    this.address,
    this.city,
    this.country,
    this.phoneNumber,
    this.email,
    this.rating,
    this.reviewCount,
    this.categories = const [],
    this.isLinked = false,
    this.linkStatus,
    required this.createdAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) {
    // Handle both 'name' (backend) and 'company_name' (legacy) fields
    final companyName = json['company_name'] as String? ?? json['name'] as String? ?? '';
    
    // Parse created_at - handle both string and timestamp formats
    DateTime createdAt;
    try {
      if (json['created_at'] is String) {
        createdAt = DateTime.parse(json['created_at'] as String);
      } else {
        // If it's already a DateTime or other format, try to convert
        createdAt = DateTime.now();
      }
    } catch (e) {
      createdAt = DateTime.now();
    }
    
    return SupplierModel(
      id: json['id'] as String? ?? '',
      companyName: companyName,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      address: json['address'] as String?,
      city: json['city'] as String?,
      country: json['country'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      rating: (json['rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isLinked: json['is_linked'] as bool? ?? false,
      linkStatus: json['link_status'] != null
          ? _parseLinkStatus(json['link_status'].toString())
          : null,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'company_name': companyName,
      'description': description,
      'logo_url': logoUrl,
      'address': address,
      'city': city,
      'country': country,
      'phone_number': phoneNumber,
      'email': email,
      'rating': rating,
      'review_count': reviewCount,
      'categories': categories,
      'is_linked': isLinked,
      'link_status': linkStatus?.name,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static LinkRequestStatus _parseLinkStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return LinkRequestStatus.pending;
      case 'accepted':
        return LinkRequestStatus.accepted;
      case 'rejected':
        return LinkRequestStatus.rejected;
      case 'blocked':
        return LinkRequestStatus.blocked;
      default:
        return LinkRequestStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        id,
        companyName,
        description,
        logoUrl,
        address,
        city,
        country,
        phoneNumber,
        email,
        rating,
        reviewCount,
        categories,
        isLinked,
        linkStatus,
        createdAt,
      ];
}

/// Link request model
class LinkRequest extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final String? supplierLogoUrl;
  final LinkRequestStatus status;
  final String? message;
  final DateTime requestedAt;
  final DateTime? respondedAt;

  const LinkRequest({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.supplierLogoUrl,
    required this.status,
    this.message,
    required this.requestedAt,
    this.respondedAt,
  });

  factory LinkRequest.fromJson(Map<String, dynamic> json) {
    return LinkRequest(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String,
      supplierLogoUrl: json['supplier_logo_url'] as String?,
      status: _parseLinkStatus(json['status'] as String),
      message: json['message'] as String?,
      requestedAt: DateTime.parse(json['requested_at'] as String),
      respondedAt: json['responded_at'] != null
          ? DateTime.parse(json['responded_at'] as String)
          : null,
    );
  }

  static LinkRequestStatus _parseLinkStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return LinkRequestStatus.pending;
      case 'accepted':
        return LinkRequestStatus.accepted;
      case 'rejected':
        return LinkRequestStatus.rejected;
      case 'blocked':
        return LinkRequestStatus.blocked;
      default:
        return LinkRequestStatus.pending;
    }
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        supplierLogoUrl,
        status,
        message,
        requestedAt,
        respondedAt,
      ];
}

enum LinkRequestStatus {
  pending,
  accepted,
  rejected,
  blocked,
}

