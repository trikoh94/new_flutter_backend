import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/idea.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';

class QuickIdeaScreen extends StatefulWidget {
  const QuickIdeaScreen({super.key});

  @override
  State<QuickIdeaScreen> createState() => _QuickIdeaScreenState();
}

class _QuickIdeaScreenState extends State<QuickIdeaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _firebaseService = FirebaseService();
  String? _selectedProjectId;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveIdea() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isLoading = true);
      try {
        final idea = Idea(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text,
          description: _descriptionController.text,
          projectId: _selectedProjectId,
          x: 0,
          y: 0,
          connectedIdeas: [],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        await _firebaseService.saveIdea(idea);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('아이디어가 저장되었습니다')),
          );
          context.pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('오류가 발생했습니다: $e')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Idea'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: '제목',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value?.isEmpty ?? true ? '제목을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: '설명',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) =>
                    value?.isEmpty ?? true ? '설명을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),
              StreamBuilder<List<ProjectModel>>(
                stream: _firebaseService.getProjects(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  }

                  if (!snapshot.hasData) {
                    return const CircularProgressIndicator();
                  }

                  final projects = snapshot.data!;
                  return DropdownButtonFormField<String>(
                    value: _selectedProjectId,
                    decoration: const InputDecoration(
                      labelText: '프로젝트',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('프로젝트 없음'),
                      ),
                      ...projects.map((project) => DropdownMenuItem(
                            value: project.id,
                            child: Text(project.title),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() => _selectedProjectId = value);
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _saveIdea,
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('저장'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
