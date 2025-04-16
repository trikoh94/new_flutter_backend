import 'dart:js_util';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/ideas_screen.dart';
import 'screens/mind_map_screen.dart';
import 'screens/portfolio_screen.dart';
import 'screens/community_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/ai/portfolio_development_screen.dart';
import 'screens/ai/mind_map_analyzer_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:js' as js;
import 'firebase_options.dart';
import 'config/go_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/config.env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Ideation',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: router,
    );
  }
}

class Idea {
  final String id;
  final String title;
  final String description;
  final DateTime createdAt;
  final List<String> connectedIdeas;

  Idea({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.connectedIdeas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
      'connectedIdeas': connectedIdeas,
    };
  }

  factory Idea.fromMap(Map<String, dynamic> map) {
    return Idea(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      createdAt: DateTime.parse(map['createdAt']),
      connectedIdeas: List<String>.from(map['connectedIdeas']),
    );
  }
}
