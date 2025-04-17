import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'idea.g.dart';

@HiveType(typeId: 0)
class Idea {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? projectId;

  @HiveField(4)
  final double x; // 마인드맵에서의 x 좌표

  @HiveField(5)
  final double y; // 마인드맵에서의 y 좌표

  @HiveField(6)
  final List<String> connectedIdeas;

  @HiveField(7)
  final DateTime createdAt;

  @HiveField(8)
  final DateTime updatedAt;

  @HiveField(9)
  final bool isShared;

  @HiveField(10)
  final DateTime? sharedAt;

  @HiveField(11)
  final bool isAIGenerated;

  Idea({
    required this.id,
    required this.title,
    required this.description,
    this.projectId,
    required this.x,
    required this.y,
    required this.connectedIdeas,
    required this.createdAt,
    required this.updatedAt,
    this.isShared = false,
    this.sharedAt,
    this.isAIGenerated = false,
  });

  factory Idea.create({
    required String title,
    required String description,
  }) {
    return Idea(
      id: const Uuid().v4(),
      title: title,
      description: description,
      projectId: null,
      x: 0,
      y: 0,
      connectedIdeas: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Idea copyWith({
    String? title,
    String? description,
    String? projectId,
    List<String>? connectedIdeas,
    double? x,
    double? y,
    bool? isShared,
    DateTime? sharedAt,
    bool? isAIGenerated,
  }) {
    return Idea(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      x: x ?? this.x,
      y: y ?? this.y,
      connectedIdeas: connectedIdeas ?? this.connectedIdeas,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      isShared: isShared ?? this.isShared,
      sharedAt: sharedAt ?? this.sharedAt,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectId': projectId,
      'x': x,
      'y': y,
      'connectedIdeas': connectedIdeas,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isShared': isShared,
      'sharedAt': sharedAt?.toIso8601String(),
      'isAIGenerated': isAIGenerated,
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    return Idea(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String,
      projectId: map['projectId'] as String?,
      x: (map['x'] as num).toDouble(),
      y: (map['y'] as num).toDouble(),
      connectedIdeas: List<String>.from(map['connectedIdeas'] ?? []),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isShared: map['isShared'] ?? false,
      sharedAt: map['sharedAt'] != null
          ? DateTime.parse(map['sharedAt'] as String)
          : null,
      isAIGenerated: map['isAIGenerated'] ?? false,
    );
  }
}
