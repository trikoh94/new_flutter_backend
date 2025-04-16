import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class HuggingFaceService {
  final String _apiKey = dotenv.env['HUGGINGFACE_API_KEY'] ?? '';
  final String _baseUrl = 'https://api-inference.huggingface.co/models';

  Future<String> generateText(String prompt,
      {String model = 'google/flan-t5-base'}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$model'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'max_length': 100,
          'temperature': 0.7,
          'top_p': 0.9,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['generated_text'];
    } else {
      throw Exception('Failed to generate text: ${response.statusCode}');
    }
  }

  Future<String> summarizeText(String text,
      {String model = 'facebook/bart-large-cnn'}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$model'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': text,
        'parameters': {
          'max_length': 130,
          'min_length': 30,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['summary_text'];
    } else {
      throw Exception('Failed to summarize text: ${response.statusCode}');
    }
  }

  Future<String> translateText(String text,
      {String model = 'Helsinki-NLP/opus-mt-en-ko'}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$model'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': text,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['translation_text'];
    } else {
      throw Exception('Failed to translate text: ${response.statusCode}');
    }
  }

  Future<String> generateImage(String prompt,
      {String model = 'stabilityai/stable-diffusion-2'}) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/$model'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'inputs': prompt,
        'parameters': {
          'num_inference_steps': 50,
          'guidance_scale': 7.5,
        },
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data[0]['generated_image'];
    } else {
      throw Exception('Failed to generate image: ${response.statusCode}');
    }
  }
}
