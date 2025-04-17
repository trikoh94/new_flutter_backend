import 'package:flutter_dotenv/flutter_dotenv.dart';

class AIConfig {
  // API endpoints
  static const String baseUrl =
      'https://ai-sdk-starter-groq-tau-five.vercel.app';
  static const String chatEndpoint = '$baseUrl/api/chat';

  // API Key from environment variables - not needed for backend API
  static String get apiKey => '';

  // Request configurations
  static const int requestTimeout = 30000; // 30 seconds
  static const int maxRetries = 3;

  // Headers for API requests
  static Map<String, String> get headers => {
        'Content-Type': 'application/json',
      };

  // Model configurations
  static const String defaultModel =
      'meta-llama/llama-4-scout-17b-16e-instruct';
  static const double temperature = 0.7;
  static const int maxTokens = 1000;

  // Error messages
  static const String apiKeyMissing = 'API key is not configured';
  static const String requestFailed = 'Failed to make request to AI service';
  static const String invalidResponse = 'Invalid response from AI service';

  // Feature flags
  static const bool enableStreaming = true;
  static const bool enableCache = true;

  // Cache configurations
  static const int cacheDuration = 3600; // 1 hour in seconds
  static const int maxCacheSize = 100; // Maximum number of cached responses
}
