import 'http_service.dart';
import '../models/complaint_model.dart';

/// Service for managing complaints
class ComplaintService {
  final HttpService _httpService;

  ComplaintService({HttpService? httpService})
      : _httpService = httpService ?? HttpService();

  /// Log a complaint
  Future<ComplaintModel> logComplaint({
    required String conversationId,
    required String consumerId,
    required String title,
    required String description,
    ComplaintPriority priority = ComplaintPriority.medium,
    String? orderId,
    List<String>? attachments,
  }) async {
    try {
      final response = await _httpService.post(
        '/supplier/complaints',
        data: {
          'conversation_id': conversationId,
          'consumer_id': consumerId,
          'title': title,
          'description': description,
          'priority': priority.name,
          if (orderId != null) 'order_id': orderId,
          if (attachments != null) 'attachments': attachments,
        },
      );

      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to log complaint: $e');
    }
  }

  /// Get complaints
  Future<List<ComplaintModel>> getComplaints({
    ComplaintStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await _httpService.get(
        '/supplier/complaints',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (status != null) 'status': status.name,
        },
      );

      final List<dynamic> data = response.data['results'] as List<dynamic>;
      return data
          .map((e) => ComplaintModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get complaints: $e');
    }
  }

  /// Get complaint details
  Future<ComplaintModel> getComplaintDetails(String complaintId) async {
    try {
      final response = await _httpService.get('/supplier/complaints/$complaintId');
      return ComplaintModel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception('Failed to get complaint details: $e');
    }
  }

  /// Escalate complaint to manager
  Future<void> escalateComplaint(String complaintId) async {
    try {
      await _httpService.post('/supplier/complaints/$complaintId/escalate');
    } catch (e) {
      throw Exception('Failed to escalate complaint: $e');
    }
  }

  /// Update complaint status
  Future<void> updateComplaintStatus(
    String complaintId,
    ComplaintStatus status, {
    String? resolutionNotes,
  }) async {
    try {
      await _httpService.put(
        '/supplier/complaints/$complaintId',
        data: {
          'status': status.name,
          if (resolutionNotes != null) 'resolution_notes': resolutionNotes,
        },
      );
    } catch (e) {
      throw Exception('Failed to update complaint status: $e');
    }
  }
}

