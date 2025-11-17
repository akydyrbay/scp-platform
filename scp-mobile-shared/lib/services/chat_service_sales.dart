import 'dart:io';
import 'http_service.dart';
import '../models/message_model.dart';
import '../models/conversation_model.dart';

/// Chat service for sales representatives
class ChatServiceSales {
  final HttpService _httpService;

  ChatServiceSales({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Get all conversations for sales rep
  Future<List<ConversationModelSales>> getConversations() async {
    try {
      final response = await _httpService.get('/supplier/conversations');
      final dynamic payload = response.data;
      final dynamic list =
          (payload is Map && payload['results'] is List) ? payload['results']
          : (payload is Map && payload['data'] is List) ? payload['data']
          : (payload is List) ? payload
          : <dynamic>[];

      final List<dynamic> data = list as List<dynamic>;
      return data
          .map((e) => ConversationModelSales.fromJson(e as Map<String, dynamic>))
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
        '/supplier/conversations/$conversationId/messages',
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
      return data
          .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
          .toList();
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
        '/supplier/conversations/$conversationId/messages',
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
        '/supplier/conversations/$conversationId/messages',
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
        '/supplier/conversations/$conversationId/messages',
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

  /// Mark messages as read
  Future<void> markMessagesAsRead(String conversationId) async {
    try {
      await _httpService.post('/supplier/conversations/$conversationId/mark-read');
    } catch (e) {
      throw Exception('Failed to mark messages as read: $e');
    }
  }
}

