import 'package:equatable/equatable.dart';

/// Conversation model for supplier sales reps
class ConversationModelSales extends Equatable {
  final String id;
  final String consumerId;
  final String consumerName;
  final String? consumerCompanyName;
  final String? consumerAvatarUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? orderId;
  final String? orderNumber;
  final bool hasActiveComplaint;
  final DateTime createdAt;

  const ConversationModelSales({
    required this.id,
    required this.consumerId,
    required this.consumerName,
    this.consumerCompanyName,
    this.consumerAvatarUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.orderId,
    this.orderNumber,
    this.hasActiveComplaint = false,
    required this.createdAt,
  });

  factory ConversationModelSales.fromJson(Map<String, dynamic> json) {
    return ConversationModelSales(
      id: json['id'] as String,
      consumerId: json['consumer_id'] as String,
      consumerName: json['consumer_name'] as String,
      consumerCompanyName: json['consumer_company_name'] as String?,
      consumerAvatarUrl: json['consumer_avatar_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      hasActiveComplaint: json['has_active_complaint'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'consumer_id': consumerId,
      'consumer_name': consumerName,
      'consumer_company_name': consumerCompanyName,
      'consumer_avatar_url': consumerAvatarUrl,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'order_id': orderId,
      'order_number': orderNumber,
      'has_active_complaint': hasActiveComplaint,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        consumerId,
        consumerName,
        consumerCompanyName,
        consumerAvatarUrl,
        lastMessage,
        lastMessageTime,
        unreadCount,
        orderId,
        orderNumber,
        hasActiveComplaint,
        createdAt,
      ];
}

