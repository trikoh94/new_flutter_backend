import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/ai_config.dart';

class IdeaGeneratorScreen extends StatefulWidget {
  final String projectId;

  const IdeaGeneratorScreen({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  State<IdeaGeneratorScreen> createState() => _IdeaGeneratorScreenState();
}

class _IdeaGeneratorScreenState extends State<IdeaGeneratorScreen> {
  final TextEditingController _promptController = TextEditingController();
  String _generatedIdea = '';
  bool _isLoading = false;

  Future<void> _generateIdea() async {
    if (_promptController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
      _generatedIdea = '';
    });

    try {
      final response = await http.post(
        Uri.parse(AIConfig.chatEndpoint),
        headers: AIConfig.headers,
        body: jsonEncode({
          'model': AIConfig.defaultModel,
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a creative idea generator. Generate innovative and practical ideas based on the user\'s prompt.'
            },
            {'role': 'user', 'content': _promptController.text}
          ],
          'temperature': AIConfig.temperature,
          'max_tokens': AIConfig.maxTokens,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _generatedIdea = data['choices'][0]['message']['content'];
        });
      } else {
        setState(() {
          _generatedIdea = 'Error: ${response.statusCode} - ${response.body}';
        });
      }
    } catch (e) {
      setState(() {
        _generatedIdea = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Idea Generator'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _promptController,
              decoration: const InputDecoration(
                labelText: 'Enter your idea prompt',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _generateIdea,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Generate Idea'),
            ),
            const SizedBox(height: 24),
            if (_generatedIdea.isNotEmpty) ...[
              const Text(
                'Generated Idea:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_generatedIdea),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }
}
