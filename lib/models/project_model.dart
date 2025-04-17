import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'package:hive/hive.dart';

part 'project_model.g.dart';

@HiveType(typeId: 1)
class ProjectModel {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final List<String> technologies;

  @HiveField(5)
  final String? githubUrl;

  @HiveField(6)
  final String? demoUrl;

  @HiveField(7)
  final List<String> images;

  @HiveField(8)
  final DateTime startDate;

  @HiveField(9)
  final DateTime createdAt;

  @HiveField(10)
  final DateTime updatedAt;

  @HiveField(11)
  final String userId;

  ProjectModel({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.technologies,
    this.githubUrl,
    this.demoUrl,
    required this.images,
    required this.startDate,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      status: json['status'] as String,
      technologies: List<String>.from(json['technologies'] as List),
      githubUrl: json['githubUrl'] as String?,
      demoUrl: json['demoUrl'] as String?,
      images: List<String>.from(json['images'] as List),
      startDate: _parseDateTime(json['startDate']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      userId: json['userId'] as String,
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
      'userId': userId,
    };
  }

  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel.fromMap(data, doc.id);
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
      'userId': userId,
    };
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
      'userId': userId,
    };
  }

  factory ProjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ProjectModel(
      id: documentId,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      status: map['status'] ?? 'In Progress',
      technologies: List<String>.from(map['technologies'] ?? []),
      githubUrl: map['githubUrl'],
      demoUrl: map['demoUrl'],
      images: List<String>.from(map['images'] ?? []),
      startDate: _parseDateTime(map['startDate']),
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
      userId: map['userId'] ?? '',
    );
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
      githubUrl: null,
      demoUrl: null,
      images: [],
      startDate: now,
      createdAt: now,
      updatedAt: now,
      userId: '',
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
    String? userId,
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
      userId: userId ?? this.userId,
    );
  }
}
