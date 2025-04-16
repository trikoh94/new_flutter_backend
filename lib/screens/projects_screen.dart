import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createProject() async {
    if (_projectNameController.text.isEmpty) return;

    final project = {
      'id': const Uuid().v4(),
      'name': _projectNameController.text,
      'description': _projectDescriptionController.text,
      'createdAt': DateTime.now().toIso8601String(),
    };

    await _firestore.collection('projects').doc(project['id']).set(project);
    _projectNameController.clear();
    _projectDescriptionController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create Project Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create New Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _projectNameController,
                      decoration: const InputDecoration(
                        labelText: 'Project Name',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _projectDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Project Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _createProject,
                      child: const Text('Create Project'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Projects List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore.collection('projects').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final projects = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: projects.length,
                    itemBuilder: (context, index) {
                      final project =
                          projects[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(project['name']),
                          subtitle: Text(project['description']),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.lightbulb_outline),
                                onPressed: () =>
                                    context.push('/projects/${project['id']}'),
                                tooltip: 'View Ideas',
                              ),
                              IconButton(
                                icon: const Icon(Icons.account_tree),
                                onPressed: () =>
                                    context.push('/mind-map/${project['id']}'),
                                tooltip: 'View Mind Map',
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
      ),
    );
  }

  @override
  void dispose() {
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }
}
