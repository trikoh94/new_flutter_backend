import 'package:cloud_firestore/cloud_firestore.dart';

class PortfolioModel {
  final String id;
  final String title;
  final String content;
  final List<String> images;
  final List<String> links;
  final DateTime createdAt;
  final DateTime updatedAt;

  PortfolioModel({
    required this.id,
    required this.title,
    required this.content,
    required this.images,
    required this.links,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PortfolioModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PortfolioModel(
      id: doc.id,
      title: data['title'] ?? '',
      content: data['content'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      links: List<String>.from(data['links'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'content': content,
      'images': images,
      'links': links,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  PortfolioModel copyWith({
    String? id,
    String? title,
    String? content,
    List<String>? images,
    List<String>? links,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PortfolioModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      images: images ?? this.images,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
