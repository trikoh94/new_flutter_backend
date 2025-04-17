import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/ai_config.dart';
import '../models/idea.dart';

class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  Future<T> _retryRequest<T>(Future<T> Function() request) async {
    int maxAttempts = AIConfig.maxRetries;
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a helpful AI assistant that generates innovative business ideas. Please provide ideas in a clear, numbered list format.'
              },
              {'role': 'user', 'content': prompt}
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            final text = data['response'];
            return text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
          } else {
            throw Exception('Invalid response format');
          }
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a business analyst AI that provides detailed portfolio insights. Please analyze the following business idea and provide a comprehensive analysis including market potential, risks, and opportunities.'
              },
              {
                'role': 'user',
                'content':
                    'Please analyze this business idea:\nTitle: ${idea.title}\nDescription: ${idea.description}'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return data['response'];
          } else {
            throw Exception('Invalid response format');
          }
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a project planning AI that provides detailed implementation steps. Please break down the implementation into clear, actionable steps.'
              },
              {
                'role': 'user',
                'content':
                    'Please provide implementation steps for:\nTitle: ${idea.title}\nDescription: ${idea.description}'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return data['response'];
          } else {
            throw Exception('Invalid response format');
          }
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are a business categorization AI. Please categorize the given business idea into the most appropriate category and provide a brief explanation.'
              },
              {
                'role': 'user',
                'content': 'Please categorize this business idea: $idea'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return data['response'];
          } else {
            throw Exception('Invalid response format');
          }
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that analyzes the similarity between business ideas. Please provide a detailed comparison and similarity analysis.'
              },
              {
                'role': 'user',
                'content':
                    'Please analyze the similarity between these two ideas:\n1. $text1\n2. $text2'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return data['response'];
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception('Failed to check similarity: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error checking similarity: $e');
      }
    });
  }

  Future<String> analyzeMindMap(List<String> ideas) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that analyzes mind maps and provides insights about the relationships between ideas. Please analyze the following ideas and identify patterns, connections, and potential synergies.'
              },
              {
                'role': 'user',
                'content':
                    'Please analyze these connected ideas:\n${ideas.map((idea) => "- $idea").join("\n")}'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return data['response'];
          } else {
            throw Exception('Invalid response format');
          }
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that generates related business ideas. Please provide 3 innovative and related ideas in a clear, numbered list format.'
              },
              {'role': 'user', 'content': 'Generate 3 related ideas for: $idea'}
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            final text = data['response'];
            return text
                .split('\n')
                .where((line) => line.trim().isNotEmpty)
                .toList();
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception('Failed to get suggestions: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error getting suggestions: $e');
      }
    });
  }

  Future<String> analyzeIdeas(List<Map<String, dynamic>> ideas) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that analyzes multiple business ideas and provides comprehensive insights. Please analyze the ideas and identify patterns, strengths, and potential improvements.'
              },
              {
                'role': 'user',
                'content':
                    'Please analyze these business ideas:\n${ideas.map((idea) => "- ${idea['title']}: ${idea['description']}").join("\n")}'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return data['response'];
          } else {
            throw Exception('Invalid response format');
          }
        } else {
          throw Exception('Failed to analyze ideas: ${response.statusCode}');
        }
      } catch (e) {
        throw Exception('Error analyzing ideas: $e');
      }
    });
  }

  Future<List<String>> suggestConnections(String idea) async {
    return _retryRequest(() async {
      try {
        final response = await http.post(
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that suggests potential connections and relationships between business ideas. Please provide insights in a clear, numbered list format.'
              },
              {
                'role': 'user',
                'content': 'Suggest potential connections for this idea: $idea'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            final text = data['response'];
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that provides concise summaries of business ideas. Please provide a clear and structured summary.'
              },
              {
                'role': 'user',
                'content':
                    'Please summarize this idea:\nTitle: $title\nDescription: $description'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return [
              {'summary': data['response']}
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
          Uri.parse(AIConfig.chatEndpoint),
          headers: AIConfig.headers,
          body: jsonEncode({
            'messages': [
              {
                'role': 'system',
                'content':
                    'You are an AI that provides constructive feedback on business ideas. Please provide detailed feedback including strengths, weaknesses, and suggestions for improvement.'
              },
              {
                'role': 'user',
                'content':
                    'Please provide feedback on this idea:\nTitle: $title\nDescription: $description'
              }
            ]
          }),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data['response'] != null) {
            return [
              {'feedback': data['response']}
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
