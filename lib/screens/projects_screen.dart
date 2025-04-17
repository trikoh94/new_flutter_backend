import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';
import '../widgets/project_card.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _githubUrlController = TextEditingController();
  final _demoUrlController = TextEditingController();
  final _technologiesController = TextEditingController();
  String _selectedStatus = 'In Progress';
  final FirebaseService _firebaseService = FirebaseService();
  final _uuid = const Uuid();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _githubUrlController.dispose();
    _demoUrlController.dispose();
    _technologiesController.dispose();
    super.dispose();
  }

  void _resetForm() {
    _titleController.clear();
    _descriptionController.clear();
    _githubUrlController.clear();
    _demoUrlController.clear();
    _technologiesController.clear();
    _selectedStatus = 'In Progress';
  }

  Future<void> _showCreateProjectDialog() async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Project'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a description'
                      : null,
                ),
                TextFormField(
                  controller: _githubUrlController,
                  decoration: const InputDecoration(labelText: 'GitHub URL'),
                ),
                TextFormField(
                  controller: _demoUrlController,
                  decoration: const InputDecoration(labelText: 'Demo URL'),
                ),
                TextFormField(
                  controller: _technologiesController,
                  decoration: const InputDecoration(
                    labelText: 'Technologies (comma-separated)',
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter technologies'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: ['In Progress', 'Completed', 'On Hold']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'In Progress';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _resetForm();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final now = DateTime.now();
                final project = ProjectModel(
                  id: _uuid.v4(),
                  title: _titleController.text,
                  description: _descriptionController.text,
                  githubUrl: _githubUrlController.text,
                  demoUrl: _demoUrlController.text,
                  technologies: _technologiesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .toList(),
                  status: _selectedStatus,
                  images: [],
                  startDate: now,
                  createdAt: now,
                  updatedAt: now,
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                );

                try {
                  await _firebaseService.createProject(project);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Project created successfully')),
                    );
                    Navigator.pop(context);
                    _resetForm();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error creating project: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditProjectDialog(ProjectModel project) async {
    _titleController.text = project.title;
    _descriptionController.text = project.description;
    _githubUrlController.text = project.githubUrl ?? '';
    _demoUrlController.text = project.demoUrl ?? '';
    _technologiesController.text = project.technologies.join(', ');
    _selectedStatus = project.status;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Project'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Please enter a title' : null,
                ),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter a description'
                      : null,
                ),
                TextFormField(
                  controller: _githubUrlController,
                  decoration: const InputDecoration(labelText: 'GitHub URL'),
                ),
                TextFormField(
                  controller: _demoUrlController,
                  decoration: const InputDecoration(labelText: 'Demo URL'),
                ),
                TextFormField(
                  controller: _technologiesController,
                  decoration: const InputDecoration(
                    labelText: 'Technologies (comma-separated)',
                  ),
                  validator: (value) => value?.isEmpty ?? true
                      ? 'Please enter technologies'
                      : null,
                ),
                DropdownButtonFormField<String>(
                  value: _selectedStatus,
                  items: ['In Progress', 'Completed', 'On Hold']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedStatus = value ?? 'In Progress';
                    });
                  },
                  decoration: const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              _resetForm();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                final updatedProject = project.copyWith(
                  title: _titleController.text,
                  description: _descriptionController.text,
                  githubUrl: _githubUrlController.text,
                  demoUrl: _demoUrlController.text,
                  technologies: _technologiesController.text
                      .split(',')
                      .map((e) => e.trim())
                      .toList(),
                  status: _selectedStatus,
                  updatedAt: DateTime.now(),
                );

                try {
                  await _firebaseService.updateProject(updatedProject);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Project updated successfully')),
                    );
                    Navigator.pop(context);
                    _resetForm();
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating project: $e')),
                    );
                  }
                }
              }
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: StreamBuilder<List<ProjectModel>>(
        stream: _firebaseService.getProjects(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final projects = snapshot.data ?? [];

          if (projects.isEmpty) {
            return const Center(
              child: Text('No projects yet. Create your first project!'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: ProjectCard(
                  project: project,
                  onDelete: () async {
                    try {
                      await _firebaseService.deleteProject(project.id);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Project deleted successfully')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error deleting project: $e')),
                        );
                      }
                    }
                  },
                  onEdit: () => _showEditProjectDialog(project),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectDialog,
        label: const Text('New Project'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
