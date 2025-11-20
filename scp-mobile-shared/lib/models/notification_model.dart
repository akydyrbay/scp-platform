import 'package:equatable/equatable.dart';

/// Notification model
class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String? targetId; // Order ID, Supplier ID, etc.
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    this.targetId,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    // Backend returns 'message' but Flutter model uses 'body'
    // Also handle potential type mismatches safely
    final bodyValue = json['body'] ?? json['message'];
    final body = bodyValue is String 
        ? bodyValue 
        : bodyValue?.toString() ?? '';
    
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: body,
      type: _parseNotificationType(json['type'] as String),
      targetId: json['target_id'] as String?,
      data: json['data'] is Map<String, dynamic> 
          ? json['data'] as Map<String, dynamic>
          : json['data'] is String && json['data'].isNotEmpty
              ? (json['data'] as String).startsWith('{')
                  ? null // Invalid JSON string, skip
                  : null
              : null,
      isRead: json['is_read'] is bool 
          ? json['is_read'] as bool
          : json['is_read'] is int
              ? (json['is_read'] as int) != 0
              : false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static NotificationType _parseNotificationType(String type) {
    switch (type.toLowerCase()) {
      case 'message':
        return NotificationType.message;
      case 'order_update':
        return NotificationType.orderUpdate;
      case 'link_request':
        return NotificationType.linkRequest;
      default:
        return NotificationType.other;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'type': type.name,
      'target_id': targetId,
      'data': data,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        body,
        type,
        targetId,
        data,
        isRead,
        createdAt,
      ];
}

/// Notification type enum
enum NotificationType {
  message,
  orderUpdate,
  linkRequest,
  other,
}

