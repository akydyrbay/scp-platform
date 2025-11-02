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

      final List<dynamic> data = response.data['results'] as List<dynamic>;
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

      return CannedReplyModel.fromJson(response.data as Map<String, dynamic>);
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

