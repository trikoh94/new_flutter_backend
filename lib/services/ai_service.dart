import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/idea.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  final String _baseUrl = 'https://new-backend-lac.vercel.app/api';
  final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int maxAttempts = 3;
    int attempt = 0;
    Duration delay = const Duration(seconds: 2);

    while (attempt < maxAttempts) {
      try {
        return await request();
      } catch (e) {
        attempt++;
        if (attempt == maxAttempts) {
          rethrow;
        }
        await Future.delayed(delay);
      }
    }
    throw Exception('Max retry attempts reached');
  }

  Future<List<String>> generateIdeas(String prompt) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/generate-idea'),
          headers: _headers,
          body: jsonEncode({'prompt': prompt}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null || data['generated_text'] != null) {
            final text = data['response'] ?? data['generated_text'];
            return text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to generate ideas: ${response.statusCode}');
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
          headers: _headers,
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
          if (data[0]['analysis'] != null) {
            return data[0]['analysis'];
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception(
              'Failed to get portfolio insights: ${response.statusCode}');
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
          headers: _headers,
          body: jsonEncode({
            'idea': {
              'title': idea.title,
              'description': idea.description,
            },
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['steps'] != null) {
            return data[0]['steps'];
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception(
              'Failed to get implementation steps: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error getting implementation steps: $e');
      }
    });
  }

  Future<String> categorizeIdea(String idea) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/categorize-idea'),
          headers: _headers,
          body: jsonEncode({'idea': idea}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['category'] != null) {
            return data[0]['category'];
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to categorize idea: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error categorizing idea: $e');
      }
    });
  }

  Future<String> checkSimilarity(String text1, String text2) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/check-similarity'),
          headers: _headers,
          body: jsonEncode({
            'text1': text1,
            'text2': text2,
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['similarity_analysis'] != null) {
            return data[0]['similarity_analysis'];
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to check similarity: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error checking similarity: $e');
      }
    });
  }

  Future<String> analyzeIdeas(List<Map<String, dynamic>> ideas) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze-ideas'),
          headers: _headers,
          body: jsonEncode({'ideas': ideas}),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['analysis'] != null) {
            return data[0]['analysis'];
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to analyze ideas: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error analyzing ideas: $e');
      }
    });
  }

  Future<String> analyzeMindMap(List<String> ideas) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze-ideas'),
          headers: _headers,
          body: jsonEncode({
            'ideas': ideas.map((idea) => {'text': idea}).toList(),
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['analysis'] != null) {
            return data[0]['analysis'];
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to analyze mind map: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error analyzing mind map: $e');
      }
    });
  }

  Future<List<String>> getSuggestions(String idea) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/generate-idea'),
          headers: _headers,
          body: jsonEncode({
            'prompt': 'Generate 3 related ideas for: $idea',
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null || data['generated_text'] != null) {
            final text = data['response'] ?? data['generated_text'];
            return text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
          } else {
            throw Exception('Invalid response format');
          }
        } else if (response.statusCode == 429) {
          throw Exception('Rate limit exceeded. Please try again later.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          throw Exception('Failed to get suggestions: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error getting suggestions: $e');
      }
    });
  }

  Future<List<String>> suggestConnections(String idea) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/analyze-ideas'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'ideas': [
              {'text': idea},
            ],
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['analysis'] != null) {
            final text = data[0]['analysis'];
            return text.split('\n').where((line) => line.isNotEmpty).toList();
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception(
              'Failed to suggest connections: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to suggest connections: $e');
      }
    });
  }

  Future<List<Map<String, dynamic>>> summarizeIdea(
      String title, String description) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/summarize-idea'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idea': {'title': title, 'description': description}
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['summary'] != null) {
            return [
              {'summary': data[0]['summary']}
            ];
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception('Failed to summarize idea: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to summarize idea: $e');
      }
    });
  }

  Future<List<Map<String, dynamic>>> getFeedback(
      String title, String description) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse('$_baseUrl/feedback-idea'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'idea': {'title': title, 'description': description}
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data[0]['feedback'] != null) {
            return [
              {'feedback': data[0]['feedback']}
            ];
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception('Failed to get feedback: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Failed to get feedback: $e');
      }
    });
  }
}
