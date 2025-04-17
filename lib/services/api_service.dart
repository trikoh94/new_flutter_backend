import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class ApiService {
  final String baseUrl;
  final String apiKey;

  ApiService({
    required this.baseUrl,
    required this.apiKey,
  });

  Future<String> generateIdea(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/generate-idea'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'prompt': prompt,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['generated_text'] ?? 'No idea generated';
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to generate idea: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Error generating idea: $e');
    }
  }

  Future<String> analyzeIdeas(List<Map<String, String>> ideas) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/analyze-ideas'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'ideas': ideas,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0]['analysis'] ?? 'No analysis generated';
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to analyze ideas: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Error analyzing ideas: $e');
    }
  }

  Future<String> testApi() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/test'),
        headers: {
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['message'] ?? 'API test successful';
      } else {
        print('Error response: ${response.body}');
        throw Exception('Failed to test API: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception: $e');
      throw Exception('Error testing API: $e');
    }
  }
}
