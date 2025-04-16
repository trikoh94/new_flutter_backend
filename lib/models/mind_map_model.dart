import 'package:cloud_firestore/cloud_firestore.dart';

class MindMapModel {
  final String id;
  final String title;
  final List<Node> nodes;
  final List<Connection> connections;
  final DateTime createdAt;
  final DateTime updatedAt;

  MindMapModel({
    required this.id,
    required this.title,
    required this.nodes,
    required this.connections,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MindMapModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return MindMapModel(
      id: doc.id,
      title: data['title'] ?? '',
      nodes: (data['nodes'] as List<dynamic>)
          .map((node) => Node.fromMap(node as Map<String, dynamic>))
          .toList(),
      connections: (data['connections'] as List<dynamic>)
          .map((connection) =>
              Connection.fromMap(connection as Map<String, dynamic>))
          .toList(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'nodes': nodes.map((node) => node.toMap()).toList(),
      'connections':
          connections.map((connection) => connection.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  MindMapModel copyWith({
    String? id,
    String? title,
    List<Node>? nodes,
    List<Connection>? connections,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MindMapModel(
      id: id ?? this.id,
      title: title ?? this.title,
      nodes: nodes ?? this.nodes,
      connections: connections ?? this.connections,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Node {
  final String id;
  final String text;
  final double x;
  final double y;
  final String color;
  final double fontSize;

  Node({
    required this.id,
    required this.text,
    required this.x,
    required this.y,
    required this.color,
    required this.fontSize,
  });

  factory Node.fromMap(Map<String, dynamic> map) {
    return Node(
      id: map['id'] ?? '',
      text: map['text'] ?? '',
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      color: map['color'] ?? '#000000',
      fontSize: map['fontSize']?.toDouble() ?? 16.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'x': x,
      'y': y,
      'color': color,
      'fontSize': fontSize,
    };
  }
}

class Connection {
  final String id;
  final String sourceId;
  final String targetId;
  final String color;
  final double width;

  Connection({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.color,
    required this.width,
  });

  factory Connection.fromMap(Map<String, dynamic> map) {
    return Connection(
      id: map['id'] ?? '',
      sourceId: map['sourceId'] ?? '',
      targetId: map['targetId'] ?? '',
      color: map['color'] ?? '#000000',
      width: map['width']?.toDouble() ?? 2.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sourceId': sourceId,
      'targetId': targetId,
      'color': color,
      'width': width,
    };
  }
}
