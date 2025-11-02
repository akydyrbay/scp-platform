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
      final List<dynamic> data = response.data['results'] as List<dynamic>;
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

      final List<dynamic> data = response.data['results'] as List<dynamic>;
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

      return MessageModel.fromJson(response.data as Map<String, dynamic>);
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

      return MessageModel.fromJson(response.data as Map<String, dynamic>);
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

      return MessageModel.fromJson(response.data as Map<String, dynamic>);
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

