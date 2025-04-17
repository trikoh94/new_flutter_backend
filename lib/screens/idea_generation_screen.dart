import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../config/ai_config.dart';

class IdeaGenerationScreen extends StatefulWidget {
  const IdeaGenerationScreen({super.key});

  @override
  State<IdeaGenerationScreen> createState() => _IdeaGenerationScreenState();
}

class _IdeaGenerationScreenState extends State<IdeaGenerationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _promptController = TextEditingController();
  late final ApiService _apiService;
  bool _isLoading = false;
  String? _generatedIdea;
  String? _error;
  String? _testResult;

  @override
  void initState() {
    super.initState();
    _apiService = ApiService(
      baseUrl: AIConfig.baseUrl,
      apiKey: AIConfig.apiKey,
    );
  }

  Future<void> _generateIdea() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _generatedIdea = null;
    });

    try {
      final idea = await _apiService.generateIdea(_promptController.text);
      setState(() {
        _generatedIdea = idea;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testApi() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _testResult = null;
    });

    try {
      final result = await _apiService.testApi();
      setState(() {
        _testResult = result;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Idea Generation'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _isLoading ? null : _testApi,
                child: const Text('Test API Connection'),
              ),
              if (_testResult != null) ...[
                const SizedBox(height: 16),
                Text(
                  'API Test Result: $_testResult',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _promptController,
                decoration: const InputDecoration(
                  labelText: 'Enter your prompt',
                  hintText: 'Describe what kind of idea you want to generate',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a prompt';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _generateIdea,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Generate Idea'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              if (_generatedIdea != null) ...[
                const SizedBox(height: 16),
                const Text(
                  'Generated Idea:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(_generatedIdea!),
              ],
            ],
          ),
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
