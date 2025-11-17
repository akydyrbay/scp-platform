import 'http_service.dart';
import '../models/canned_reply_model.dart';

/// Service for managing canned replies
class CannedReplyService {
  final HttpService _httpService;

  CannedReplyService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Get all canned replies
  Future<List<CannedReplyModel>> getCannedReplies({String? category}) async {
    try {
      final response = await _httpService.get(
        '/supplier/canned-replies',
        queryParameters: {
          if (category != null) 'category': category,
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
          .map((e) => CannedReplyModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get canned replies: $e');
    }
  }

  /// Create canned reply
  Future<CannedReplyModel> createCannedReply({
    required String title,
    required String content,
    required String category,
  }) async {
    try {
      final response = await _httpService.post(
        '/supplier/canned-replies',
        data: {
          'title': title,
          'content': content,
          'category': category,
        },
      );

      // Handle both direct format and wrapped format
      final dynamic payload = response.data;
      final Map<String, dynamic> replyData = (payload is Map && payload['data'] != null)
          ? payload['data'] as Map<String, dynamic>
          : payload as Map<String, dynamic>;
      return CannedReplyModel.fromJson(replyData);
    } catch (e) {
      throw Exception('Failed to create canned reply: $e');
    }
  }

  /// Delete canned reply
  Future<void> deleteCannedReply(String id) async {
    try {
      await _httpService.delete('/supplier/canned-replies/$id');
    } catch (e) {
      throw Exception('Failed to delete canned reply: $e');
    }
  }
}

