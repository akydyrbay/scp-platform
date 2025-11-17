import 'dart:io';
import '../models/message_model.dart';
import '../services/http_service.dart';

/// Chat service for messaging with suppliers
class ChatService {
  final HttpService _httpService;

  ChatService({
    HttpService? httpService,
  })  : _httpService = httpService ?? HttpService();

  /// Get all conversations
  Future<List<ConversationModel>> getConversations() async {
    try {
      final response = await _httpService.get('/consumer/conversations');
      // Handle both paginated format (results) and direct format (data)
      final dynamic payload = response.data;
      final List<dynamic> data = (payload is Map && payload['results'] != null)
          ? payload['results'] as List<dynamic>
          : (payload is Map && payload['data'] != null)
              ? payload['data'] as List<dynamic>
              : (payload is List)
                  ? payload
                  : <dynamic>[];
      return data
          .map((e) => ConversationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get conversations: $e');
    }
  }

  /// Get messages for a conversation
  Future<List<MessageModel>> getMessages(
    String conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    try {
      final response = await _httpService.get(
        '/consumer/conversations/$conversationId/messages',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
        },
      );

      // Handle both paginated format (results) and direct format (data)
      final dynamic payload = response.data;
      final List<dynamic> data = (payload is Map && payload['results'] != null)
          ? payload['results'] as List<dynamic>
          : (payload is Map && payload['data'] != null)
              ? payload['data'] as List<dynamic>
              : (payload is List)
                  ? payload
                  : <dynamic>[];
      return data.map((e) => MessageModel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception('Failed to get messages: $e');
    }
  }

  /// Send a text message
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String content,
    String? orderId,
  }) async {
    try {
      final response = await _httpService.post(
        '/consumer/conversations/$conversationId/messages',
        data: {
          'content': content,
          'type': 'text',
          if (orderId != null) 'order_id': orderId,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> messageData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return MessageModel.fromJson(messageData);
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  /// Send an image
  Future<MessageModel> sendImage({
    required String conversationId,
    required File imageFile,
    String? orderId,
  }) async {
    try {
      final response = await _httpService.postFile(
        '/consumer/conversations/$conversationId/messages',
        imageFile,
        additionalData: {
          'type': 'image',
          if (orderId != null) 'order_id': orderId,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> messageData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return MessageModel.fromJson(messageData);
    } catch (e) {
      throw Exception('Failed to send image: $e');
    }
  }

  /// Send a file
  Future<MessageModel> sendFile({
    required String conversationId,
    required File file,
    String? orderId,
  }) async {
    try {
      final response = await _httpService.postFile(
        '/consumer/conversations/$conversationId/messages',
        file,
        additionalData: {
          'type': 'file',
          if (orderId != null) 'order_id': orderId,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> messageData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return MessageModel.fromJson(messageData);
    } catch (e) {
      throw Exception('Failed to send file: $e');
    }
  }

  /// Start a conversation (or get existing one)
  Future<ConversationModel> startConversation({
    required String supplierId,
    String? orderId,
  }) async {
    try {
      final response = await _httpService.post(
        '/consumer/conversations',
        data: {
          'supplier_id': supplierId,
          if (orderId != null) 'order_id': orderId,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> convData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return ConversationModel.fromJson(convData);
    } catch (e) {
      throw Exception('Failed to start conversation: $e');
    }
  }

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _httpService.post(
        '/consumer/conversations/$conversationId/mark-read',
      );
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }

  /// Start complaint thread for an order
  Future<ConversationModel> startComplaintThread(String orderId) async {
    try {
      final response = await _httpService.post(
        '/consumer/conversations',
        data: {
          'order_id': orderId,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> convData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return ConversationModel.fromJson(convData);
    } catch (e) {
      throw Exception('Failed to start complaint thread: $e');
    }
  }
}

