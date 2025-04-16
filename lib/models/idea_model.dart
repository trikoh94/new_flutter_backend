import 'package:cloud_firestore/cloud_firestore.dart';

class IdeaModel {
  final String id;
  final String title;
  final String description;
  final List<String> tags;
  final String status; // 'draft', 'in_progress', 'completed'
  final DateTime createdAt;
  final DateTime updatedAt;

  IdeaModel({
    required this.id,
    required this.title,
    required this.description,
    required this.tags,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory IdeaModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return IdeaModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      tags: List<String>.from(data['tags'] ?? []),
      status: data['status'] ?? 'draft',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  IdeaModel copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? tags,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return IdeaModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
