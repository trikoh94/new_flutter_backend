import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'idea.dart';

part 'category.g.dart';

@HiveType(typeId: 1)
class Category {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final List<Idea> ideas;

  Category({
    required this.id,
    required this.name,
    required this.description,
    required this.createdAt,
    required this.ideas,
  });

  factory Category.create({
    required String name,
    required String description,
  }) {
    return Category(
      id: const Uuid().v4(),
      name: name,
      description: description,
      createdAt: DateTime.now(),
      ideas: [],
    );
  }

  Category copyWith({
    String? name,
    String? description,
    List<Idea>? ideas,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdAt: createdAt,
      ideas: ideas ?? this.ideas,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'ideas': ideas.map((idea) => idea.toMap()).toList(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      ideas: (map['ideas'] as List).map((idea) => Idea.fromMap(idea)).toList(),
    );
  }
}
