import 'package:flutter/material.dart';
import '../../services/ai_service.dart';
import '../../models/idea.dart';

class MindMapAnalyzerScreen extends StatefulWidget {
  final List<Idea> ideas;

  const MindMapAnalyzerScreen({
    super.key,
    required this.ideas,
  });

  @override
  State<MindMapAnalyzerScreen> createState() => _MindMapAnalyzerScreenState();
}

class _MindMapAnalyzerScreenState extends State<MindMapAnalyzerScreen> {
  final _aiService = AIService();
  bool _isLoading = false;
  String? _analysis;
  String? _errorMessage;
  List<String>? _suggestions;

  Future<void> _analyzeMindMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analysis = await _aiService.analyzeMindMap(
        widget.ideas.map((idea) => idea.title).toList(),
      );
      setState(() {
        _analysis = analysis;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getSuggestions(String idea) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final suggestions = await _aiService.suggestConnections(idea);
      setState(() {
        _suggestions = suggestions;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
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
        title: const Text('AI Mind Map Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Your Ideas:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...widget.ideas.map((idea) => Card(
                  child: ListTile(
                    title: Text(idea.title),
                    subtitle: Text(idea.description),
                    trailing: IconButton(
                      icon: const Icon(Icons.lightbulb),
                      onPressed: () => _getSuggestions(idea.title),
                      tooltip: 'Get Suggestions',
                    ),
                  ),
                )),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _analyzeMindMap,
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Analyze Mind Map'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ],
            if (_analysis != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Analysis:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_analysis!),
                ),
              ),
            ],
            if (_suggestions != null) ...[
              const SizedBox(height: 24),
              const Text(
                'Suggested Connections:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ..._suggestions!.map((suggestion) => Card(
                    child: ListTile(
                      title: Text(suggestion),
                      trailing: IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          // TODO: Add suggestion as a new idea
                        },
                      ),
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}
