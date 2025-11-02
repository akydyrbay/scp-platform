import 'package:equatable/equatable.dart';

/// Complaint/Incident model
class ComplaintModel extends Equatable {
  final String id;
  final String conversationId;
  final String consumerId;
  final String consumerName;
  final String? orderId;
  final String? orderNumber;
  final String title;
  final String description;
  final ComplaintStatus status;
  final ComplaintPriority priority;
  final DateTime reportedAt;
  final DateTime? resolvedAt;
  final String? resolutionNotes;
  final bool escalated;
  final String? escalatedTo;
  final DateTime? escalatedAt;
  final List<String> attachments;

  const ComplaintModel({
    required this.id,
    required this.conversationId,
    required this.consumerId,
    required this.consumerName,
    this.orderId,
    this.orderNumber,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.reportedAt,
    this.resolvedAt,
    this.resolutionNotes,
    this.escalated = false,
    this.escalatedTo,
    this.escalatedAt,
    this.attachments = const [],
  });

  factory ComplaintModel.fromJson(Map<String, dynamic> json) {
    return ComplaintModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      consumerId: json['consumer_id'] as String,
      consumerName: json['consumer_name'] as String,
      orderId: json['order_id'] as String?,
      orderNumber: json['order_number'] as String?,
      title: json['title'] as String,
      description: json['description'] as String,
      status: _parseStatus(json['status'] as String),
      priority: _parsePriority(json['priority'] as String),
      reportedAt: DateTime.parse(json['reported_at'] as String),
      resolvedAt: json['resolved_at'] != null
          ? DateTime.parse(json['resolved_at'] as String)
          : null,
      resolutionNotes: json['resolution_notes'] as String?,
      escalated: json['escalated'] as bool? ?? false,
      escalatedTo: json['escalated_to'] as String?,
      escalatedAt: json['escalated_at'] != null
          ? DateTime.parse(json['escalated_at'] as String)
          : null,
      attachments: (json['attachments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  static ComplaintStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return ComplaintStatus.open;
      case 'in_progress':
        return ComplaintStatus.inProgress;
      case 'resolved':
        return ComplaintStatus.resolved;
      case 'closed':
        return ComplaintStatus.closed;
      default:
        return ComplaintStatus.open;
    }
  }

  static ComplaintPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return ComplaintPriority.low;
      case 'medium':
        return ComplaintPriority.medium;
      case 'high':
        return ComplaintPriority.high;
      case 'urgent':
        return ComplaintPriority.urgent;
      default:
        return ComplaintPriority.medium;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversation_id': conversationId,
      'consumer_id': consumerId,
      'consumer_name': consumerName,
      'order_id': orderId,
      'order_number': orderNumber,
      'title': title,
      'description': description,
      'status': status.name,
      'priority': priority.name,
      'reported_at': reportedAt.toIso8601String(),
      'resolved_at': resolvedAt?.toIso8601String(),
      'resolution_notes': resolutionNotes,
      'escalated': escalated,
      'escalated_to': escalatedTo,
      'escalated_at': escalatedAt?.toIso8601String(),
      'attachments': attachments,
    };
  }

  @override
  List<Object?> get props => [
        id,
        conversationId,
        consumerId,
        consumerName,
        orderId,
        orderNumber,
        title,
        description,
        status,
        priority,
        reportedAt,
        resolvedAt,
        resolutionNotes,
        escalated,
        escalatedTo,
        escalatedAt,
        attachments,
      ];
}

enum ComplaintStatus {
  open,
  inProgress,
  resolved,
  closed,
}

enum ComplaintPriority {
  low,
  medium,
  high,
  urgent,
}

