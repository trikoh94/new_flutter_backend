import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/idea.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  String get _baseUrl => 'http://192.168.0.5:3006/api';

  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int attempts = 0;
    const maxAttempts = 3;
    const retryDelay = Duration(seconds: 2);

    while (attempts < maxAttempts) {
      try {
        return await request();
      } catch (e) {
        attempts++;
        if (attempts == maxAttempts) {
          rethrow;
        }
        await Future.delayed(retryDelay * attempts);
      }
    }
    throw Exception('Max retry attempts reached');
  }

  Future<String> generateIdeas(String prompt) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/generate-idea'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'prompt': prompt}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['ideas'] as String;
        } else {
          throw Exception('Failed to generate ideas');
        }
      } catch (e) {
        throw Exception('Error generating ideas: $e');
      }
    });
  }

  Future<String> getPortfolioInsights(Idea idea) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze-ideas'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ideas': [
              {
                'title': idea.title,
                'description': idea.description,
              }
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['analysis'] as String;
        } else {
          throw Exception('Failed to get portfolio insights');
        }
      } catch (e) {
        throw Exception('Error getting portfolio insights: $e');
      }
    });
  }

  Future<String> getImplementationSteps(Idea idea) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/implementation-plan'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idea': {
              'title': idea.title,
              'description': idea.description,
            },
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['steps'] as String;
        } else {
          throw Exception('Failed to get implementation steps');
        }
      } catch (e) {
        throw Exception('Error getting implementation steps: $e');
      }
    });
  }

  // Text classification for idea categorization
  Future<String> categorizeIdea(String idea) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/categorize-idea'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idea': idea}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['category'] != null) {
          return data[0]['category'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to categorize idea: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in categorizeIdea: $e');
      throw Exception('Failed to categorize idea. Please try again later.');
    }
  }

  // Text similarity check for idea connections
  Future<String> checkSimilarity(String text1, String text2) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/check-similarity'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text1': text1,
          'text2': text2,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty && data[0]['similarity_analysis'] != null) {
          return data[0]['similarity_analysis'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to check similarity: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in checkSimilarity: $e');
      throw Exception('Failed to check similarity. Please try again later.');
    }
  }

  // 아이디어 분석
  Future<String> analyzeIdeas(List<Map<String, dynamic>> ideas) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/analyze-ideas'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'ideas': ideas}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['analysis'] != null) {
          return data['analysis'];
        } else {
          throw Exception('Invalid response format');
        }
      } else {
        throw Exception('Failed to analyze ideas: ${response.statusCode}');
      }
    } catch (e) {
      print('Error in analyzeIdeas: $e');
      throw Exception('Failed to analyze ideas. Please try again later.');
    }
  }

  Future<String> analyzeMindMap(List<String> ideas) async {
    // TODO: Implement OpenAI API call
    return "Analysis of ideas: ${ideas.join(", ")}";
  }

  Future<List<String>> getSuggestions(String idea) async {
    // TODO: Implement OpenAI API call
    return ["Suggestion 1 for $idea", "Suggestion 2 for $idea"];
  }

  Future<List<String>> suggestConnections(String idea) async {
    // TODO: Implement AI suggestions
    return ['Suggestion 1', 'Suggestion 2', 'Suggestion 3'];
  }

  Future<List<Map<String, dynamic>>> summarizeIdea(
      String title, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/summarize-idea'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idea': {'title': title, 'description': description}
        }),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to summarize idea: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error summarizing idea: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getFeedback(
      String title, String description) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/feedback-idea'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idea': {'title': title, 'description': description}
        }),
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Failed to get feedback: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting feedback: $e');
    }
  }
}
