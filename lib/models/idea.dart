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
  final DateTime createdAt;

  @HiveField(4)
  final List<String> connectedIdeas;

  @HiveField(5)
  final double x; // 마인드맵에서의 x 좌표

  @HiveField(6)
  final double y; // 마인드맵에서의 y 좌표

  @HiveField(7)
  final bool isShared;

  @HiveField(8)
  final DateTime? sharedAt;

  @HiveField(9)
  final bool isAIGenerated;

  Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.connectedIdeas,
    required this.x,
    required this.y,
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
      createdAt: DateTime.now(),
      connectedIdeas: [],
      x: 0,
      y: 0,
      isAIGenerated: false,
    );
  }

  Idea copyWith({
    String? title,
    String? description,
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
      createdAt: createdAt,
      connectedIdeas: connectedIdeas ?? this.connectedIdeas,
      x: x ?? this.x,
      y: y ?? this.y,
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
      'createdAt': createdAt.toIso8601String(),
      'connectedIdeas': connectedIdeas,
      'x': x,
      'y': y,
      'isShared': isShared,
      'sharedAt': sharedAt?.toIso8601String(),
      'isAIGenerated': isAIGenerated,
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    return Idea(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      connectedIdeas: List<String>.from(map['connectedIdeas']),
      x: map['x'] ?? 0,
      y: map['y'] ?? 0,
      isShared: map['isShared'] ?? false,
      sharedAt:
          map['sharedAt'] != null ? DateTime.parse(map['sharedAt']) : null,
      isAIGenerated: map['isAIGenerated'] ?? false,
    );
  }
}
