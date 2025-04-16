import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ProjectModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final List<String> technologies;
  final String githubUrl;
  final String demoUrl;
  final List<String> images;
  final DateTime startDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.technologies,
    required this.githubUrl,
    required this.demoUrl,
    required this.images,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      technologies: List<String>.from(json['technologies'] as List),
      githubUrl: json['githubUrl'] as String,
      demoUrl: json['demoUrl'] as String,
      images: List<String>.from(json['images'] as List),
      startDate: _parseDateTime(json['startDate']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'technologies': technologies,
      'githubUrl': githubUrl,
      'demoUrl': demoUrl,
      'images': images,
      'startDate': startDate.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'planning',
      technologies: List<String>.from(data['technologies'] ?? []),
      githubUrl: data['githubUrl'] ?? '',
      demoUrl: data['demoUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      startDate: _parseDateTime(data['startDate']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'status': status,
      'technologies': technologies,
      'githubUrl': githubUrl,
      'demoUrl': demoUrl,
      'images': images,
      'startDate': Timestamp.fromDate(startDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> data) {
    return ProjectModel(
      id: data['id'] as String,
      title: data['title'] ?? data['name'] ?? '',
      description: data['description'] ?? '',
      status: data['status'] ?? 'active',
      technologies: List<String>.from(data['technologies'] ?? []),
      githubUrl: data['githubUrl'] ?? '',
      demoUrl: data['demoUrl'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      startDate: _parseDateTime(data['startDate']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'technologies': technologies,
      'githubUrl': githubUrl,
      'demoUrl': demoUrl,
      'images': images,
      'startDate': Timestamp.fromDate(startDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ProjectModel.create({
    required String name,
    required String description,
  }) {
    final now = DateTime.now();
    return ProjectModel(
      id: const Uuid().v4(),
      title: name,
      description: description,
      status: 'active',
      technologies: [],
      githubUrl: '',
      demoUrl: '',
      images: [],
      startDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  ProjectModel copyWith({
    String? id,
    String? title,
    String? description,
    String? status,
    List<String>? technologies,
    String? githubUrl,
    String? demoUrl,
    List<String>? images,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      technologies: technologies ?? this.technologies,
      githubUrl: githubUrl ?? this.githubUrl,
      demoUrl: demoUrl ?? this.demoUrl,
      images: images ?? this.images,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
