import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/idea.dart';
import '../../services/ai_service.dart';
import '../../services/firebase_service.dart';
import '../../widgets/idea_edit_form.dart';

class PortfolioDevelopmentScreen extends StatefulWidget {
  final String projectId;

  const PortfolioDevelopmentScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<PortfolioDevelopmentScreen> createState() =>
      _PortfolioDevelopmentScreenState();
}

class _PortfolioDevelopmentScreenState extends State<PortfolioDevelopmentScreen>
    with SingleTickerProviderStateMixin {
  final AIService _aiService = AIService();
  final FirebaseService _firebaseService = FirebaseService();
  final TextEditingController _ideaController = TextEditingController();
  final List<String> _selectedIdeas = [];
  bool _isRefinementMode = false;
  bool _isLoading = false;
  String? _summaryResult;
  String? _portfolioInsights;
  String? _implementationSteps;
  late TabController _tabController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _validateProjectId();
  }

  Future<void> _validateProjectId() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(widget.projectId)
          .get();

      if (!doc.exists) {
        setState(() {
          _errorMessage = 'Project not found';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading project: $e';
      });
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _ideaController.dispose();
    super.dispose();
  }

  Future<void> _generateIdeas() async {
    if (_ideaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter an idea or project description')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _summaryResult = null;
      _portfolioInsights = null;
      _implementationSteps = null;
    });

    try {
      final ideas = await _aiService.generateIdeas(_ideaController.text);
      setState(() {
        _summaryResult = ideas;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error generating ideas: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getPortfolioInsights(Idea idea) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final insights = await _aiService.getPortfolioInsights(idea);
      setState(() {
        _portfolioInsights = insights;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting portfolio insights: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getImplementationSteps(Idea idea) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final steps = await _aiService.getImplementationSteps(idea);
      setState(() {
        _implementationSteps = steps;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error getting implementation steps: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveToPortfolio(Idea idea) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _firebaseService.saveToPortfolio(
        widget.projectId,
        idea.id,
        {
          'summary': _summaryResult,
          'feedback': _portfolioInsights,
          'implementationSteps': _implementationSteps,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Saved to portfolio successfully')),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error saving to portfolio: $e';
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _showEditDialog(Idea idea) async {
    final titleController = TextEditingController(text: idea.title);
    final descriptionController = TextEditingController(text: idea.description);

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Idea'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, {
              'title': titleController.text,
              'description': descriptionController.text,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedIdea = Idea(
        id: idea.id,
        title: result['title']!,
        description: result['description']!,
        createdAt: idea.createdAt,
        connectedIdeas: idea.connectedIdeas,
        x: idea.x,
        y: idea.y,
        isShared: idea.isShared,
      );
      await _firebaseService.updateIdea(widget.projectId, updatedIdea);
      setState(() {
        _errorMessage = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Portfolio Development Hub'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });
                  _validateProjectId();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portfolio Development Hub'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Analysis'),
            Tab(text: 'Portfolio'),
            Tab(text: 'Implementation'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildAnalysisView(),
              _buildPortfolioView(),
              _buildImplementationView(),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAnalysisView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ideaController,
            decoration: const InputDecoration(
              labelText: 'Enter your idea or project description',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _generateIdeas,
            child: const Text('Analyze Idea'),
          ),
          if (_summaryResult != null) ...[
            const SizedBox(height: 24),
            const Text(
              'Analysis Results',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_summaryResult!),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPortfolioView() {
    return StreamBuilder<List<Idea>>(
      stream: _firebaseService.getIdeas(widget.projectId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final ideas = snapshot.data!;
        if (ideas.isEmpty) {
          return const Center(
            child: Text('No ideas saved to portfolio yet.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ideas.length,
          itemBuilder: (context, index) {
            final idea = ideas[index];
            return _buildIdeaCard(idea);
          },
        );
      },
    );
  }

  Widget _buildImplementationView() {
    return StreamBuilder<List<Idea>>(
      stream: _firebaseService.getIdeas(widget.projectId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final ideas = snapshot.data!;
        if (ideas.isEmpty) {
          return const Center(
            child: Text('No ideas available for implementation planning.'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: ideas.length,
          itemBuilder: (context, index) {
            final idea = ideas[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                children: [
                  ListTile(
                    title: Text(idea.title),
                    subtitle: Text(idea.description),
                  ),
                  if (_implementationSteps != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Implementation Plan',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_implementationSteps!),
                        ],
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _getImplementationSteps(idea),
                          icon: const Icon(Icons.assignment),
                          label: const Text('Generate Plan'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIdeaCard(Idea idea) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              idea.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              idea.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditDialog(idea),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _getPortfolioInsights(idea),
                  icon: const Icon(Icons.insights),
                  label: const Text('Portfolio Insights'),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => _saveToPortfolio(idea),
                  icon: const Icon(Icons.save),
                  label: const Text('Save to Portfolio'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
