import 'package:equatable/equatable.dart';

/// Canned reply model for quick message templates
class CannedReplyModel extends Equatable {
  final String id;
  final String title;
  final String content;
  final String category;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const CannedReplyModel({
    required this.id,
    required this.title,
    required this.content,
    required this.category,
    required this.createdAt,
    this.updatedAt,
  });

  factory CannedReplyModel.fromJson(Map<String, dynamic> json) {
    return CannedReplyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        title,
        content,
        category,
        createdAt,
        updatedAt,
      ];
}

