import 'package:equatable/equatable.dart';

/// Chat message model
class MessageModel extends Equatable {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String? senderAvatarUrl;
  final String content;
  final MessageType type;
  final String? fileUrl;
  final String? fileName;
  final int? fileSizeBytes;
  final DateTime timestamp;
  final bool isRead;
  final String? orderId; // For complaint threads

  const MessageModel({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    this.senderAvatarUrl,
    required this.content,
    required this.type,
    this.fileUrl,
    this.fileName,
    this.fileSizeBytes,
    required this.timestamp,
    this.isRead = false,
    this.orderId,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: json['sender_name'] as String,
      senderAvatarUrl: json['sender_avatar_url'] as String?,
      content: json['content'] as String,
      type: _parseMessageType(json['type'] as String),
      fileUrl: json['file_url'] as String?,
      fileName: json['file_name'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isRead: json['is_read'] as bool? ?? false,
      orderId: json['order_id'] as String?,
    );
  }

  static MessageType _parseMessageType(String type) {
    switch (type.toLowerCase()) {
      case 'text':
        return MessageType.text;
      case 'image':
        return MessageType.image;
      case 'file':
        return MessageType.file;
      default:
        return MessageType.text;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'sender_id': senderId,
      'sender_name': senderName,
      'sender_avatar_url': senderAvatarUrl,
      'content': content,
      'type': type.name,
      'file_url': fileUrl,
      'file_name': fileName,
      'file_size_bytes': fileSizeBytes,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead,
      'order_id': orderId,
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        senderId,
        senderName,
        senderAvatarUrl,
        content,
        type,
        fileUrl,
        fileName,
        fileSizeBytes,
        timestamp,
        isRead,
        orderId,
      ];
}

/// Message type enum
enum MessageType {
  text,
  image,
  file,
}

/// Conversation model
class ConversationModel extends Equatable {
  final String id;
  final String supplierId;
  final String supplierName;
  final String? supplierLogoUrl;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final int unreadCount;
  final String? orderId;
  final DateTime createdAt;

  const ConversationModel({
    required this.id,
    required this.supplierId,
    required this.supplierName,
    this.supplierLogoUrl,
    this.lastMessage,
    this.lastMessageTime,
    this.unreadCount = 0,
    this.orderId,
    required this.createdAt,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: json['id'] as String,
      supplierId: json['supplier_id'] as String,
      supplierName: json['supplier_name'] as String,
      supplierLogoUrl: json['supplier_logo_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      orderId: json['order_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'supplier_id': supplierId,
      'supplier_name': supplierName,
      'supplier_logo_url': supplierLogoUrl,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime?.toIso8601String(),
      'unread_count': unreadCount,
      'order_id': orderId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        supplierId,
        supplierName,
        supplierLogoUrl,
        lastMessage,
        lastMessageTime,
        unreadCount,
        orderId,
        createdAt,
      ];
}

