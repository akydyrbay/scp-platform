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
    // Handle timestamp - can be 'timestamp' or 'created_at'
    final timestampValue = json['timestamp'] ?? json['created_at'];
    final timestamp = timestampValue is String
        ? DateTime.parse(timestampValue)
        : timestampValue is DateTime
            ? timestampValue
            : DateTime.now();

    // Handle sender name - can be 'sender_name' or constructed from sender object
    String senderName = json['sender_name'] as String? ?? '';
    if (senderName.isEmpty && json['sender'] is Map) {
      final sender = json['sender'] as Map<String, dynamic>;
      if (sender['first_name'] != null && sender['last_name'] != null) {
        senderName = '${sender['first_name']} ${sender['last_name']}';
      } else if (sender['first_name'] != null) {
        senderName = sender['first_name'] as String;
      } else if (sender['company_name'] != null) {
        senderName = sender['company_name'] as String;
      } else if (sender['email'] != null) {
        senderName = sender['email'] as String;
      }
    }
    if (senderName.isEmpty) {
      senderName = json['sender_id'] as String? ?? 'Unknown';
    }

    // Handle file URL - can be 'file_url' or 'attachment_url'
    final fileUrl = json['file_url'] as String? ?? json['attachment_url'] as String?;

    // Handle message type
    final typeStr = json['type'] as String? ?? json['sender_role'] as String? ?? 'text';
    final messageType = _parseMessageType(typeStr);

    return MessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      senderName: senderName,
      senderAvatarUrl: json['sender_avatar_url'] as String? ?? 
                       (json['sender'] is Map ? (json['sender'] as Map<String, dynamic>)['profile_image_url'] as String? : null),
      content: json['content'] as String? ?? '',
      type: messageType,
      fileUrl: fileUrl,
      fileName: json['file_name'] as String?,
      fileSizeBytes: json['file_size_bytes'] as int?,
      timestamp: timestamp,
      isRead: json['is_read'] is bool 
          ? json['is_read'] as bool
          : json['is_read'] is int
              ? (json['is_read'] as int) != 0
              : false,
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
      case 'audio':
        return MessageType.audio;
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
  audio,
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
    // Safely handle id - required field
    final id = json['id'] as String?;
    if (id == null) {
      throw FormatException('Conversation id is required but was null');
    }

    // Safely handle supplier_id - required field
    final supplierId = json['supplier_id'] as String?;
    if (supplierId == null) {
      throw FormatException('Conversation supplier_id is required but was null');
    }

    // Safely handle supplier_name - check nested supplier object or flat field
    String supplierName = '';
    if (json['supplier'] is Map) {
      final supplier = json['supplier'] as Map<String, dynamic>;
      supplierName = (supplier['name'] as String?) ?? '';
    }
    if (supplierName.isEmpty) {
      supplierName = (json['supplier_name'] as String?) ?? '';
    }

    // Safely handle created_at
    final createdAtStr = (json['created_at'] as String?) ?? 
        DateTime.now().toIso8601String();

    return ConversationModel(
      id: id,
      supplierId: supplierId,
      supplierName: supplierName,
      supplierLogoUrl: json['supplier_logo_url'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageTime: json['last_message_time'] != null
          ? DateTime.parse(json['last_message_time'] as String)
          : null,
      unreadCount: json['unread_count'] as int? ?? 0,
      orderId: json['order_id'] as String?,
      createdAt: DateTime.parse(createdAtStr),
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

