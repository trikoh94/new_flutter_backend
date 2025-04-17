import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/firebase_service.dart';
import '../models/idea.dart';
import '../models/project_model.dart';

class IdeasScreen extends StatefulWidget {
  final String projectId;

  const IdeasScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<IdeasScreen> createState() => _IdeasScreenState();
}

class _IdeasScreenState extends State<IdeasScreen> {
  final TextEditingController _ideaTitleController = TextEditingController();
  final TextEditingController _ideaDescriptionController =
      TextEditingController();
  final FirebaseService _firebaseService = FirebaseService();
  ProjectModel? _project;

  @override
  void initState() {
    super.initState();
    _loadProject();
  }

  Future<void> _loadProject() async {
    final project = await _firebaseService.getProject(widget.projectId);
    if (project != null) {
      setState(() {
        _project = project;
      });
    }
  }

  Future<void> _createIdea() async {
    if (_ideaTitleController.text.isEmpty) return;

    final idea = Idea.create(
      title: _ideaTitleController.text,
      description: _ideaDescriptionController.text,
    );

    try {
      await _firebaseService.createIdea(idea, widget.projectId);
      _ideaTitleController.clear();
      _ideaDescriptionController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create idea: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_project?.title ?? 'Ideas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _ideaTitleController,
                  decoration: const InputDecoration(
                    labelText: 'Idea Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _ideaDescriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _createIdea,
                  child: const Text('Add Idea'),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<List<Idea>>(
              stream: _firebaseService.getIdeas(widget.projectId),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final ideas = snapshot.data!;
                if (ideas.isEmpty) {
                  return const Center(child: Text('No ideas yet'));
                }

                return ListView.builder(
                  itemCount: ideas.length,
                  itemBuilder: (context, index) {
                    final idea = ideas[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(idea.title),
                        subtitle: Text(idea.description),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => context.push(
                                '/edit-idea/${widget.projectId}/${idea.id}',
                              ),
                              tooltip: 'Edit Idea',
                            ),
                            IconButton(
                              icon: const Icon(Icons.share),
                              onPressed: () async {
                                try {
                                  if (idea.isShared) {
                                    await _firebaseService.unshareIdea(idea.id);
                                  } else {
                                    await _firebaseService.shareIdea(idea.id);
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to share idea: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Share to Community',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () async {
                                try {
                                  await _firebaseService.deleteIdea(
                                    idea.id,
                                    widget.projectId,
                                  );
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content:
                                            Text('Failed to delete idea: $e'),
                                      ),
                                    );
                                  }
                                }
                              },
                              tooltip: 'Delete Idea',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _ideaTitleController.dispose();
    _ideaDescriptionController.dispose();
    super.dispose();
  }
}
