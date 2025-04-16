import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/idea.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';

class QuickIdeaScreen extends StatefulWidget {
  const QuickIdeaScreen({super.key});

  @override
  State<QuickIdeaScreen> createState() => _QuickIdeaScreenState();
}

class _QuickIdeaScreenState extends State<QuickIdeaScreen> {
  final _firebaseService = FirebaseService();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _selectedProjectId;
  bool _isCreatingNewProject = false;
  final _newProjectTitleController = TextEditingController();
  final _newProjectDescriptionController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _newProjectTitleController.dispose();
    _newProjectDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveIdea() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('아이디어 제목을 입력해주세요')),
      );
      return;
    }

    String projectId = _selectedProjectId!;

    // 새 프로젝트 생성이 필요한 경우
    if (_isCreatingNewProject) {
      if (_newProjectTitleController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('프로젝트 제목을 입력해주세요')),
        );
        return;
      }

      final project = ProjectModel.create(
        name: _newProjectTitleController.text,
        description: _newProjectDescriptionController.text,
      );
      await _firebaseService.createProject(project);
      projectId = project.id;
    }

    // 아이디어 생성
    final idea = Idea(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text,
      description: _descriptionController.text,
      createdAt: DateTime.now(),
      connectedIdeas: [],
      x: 0,
      y: 0,
      isShared: false,
    );

    await _firebaseService.createIdea(projectId, idea);

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('빠른 아이디어 입력'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 아이디어 입력 섹션
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '아이디어',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: '아이디어 제목',
                        hintText: '아이디어의 제목을 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: '아이디어 설명',
                        hintText: '아이디어에 대한 설명을 입력하세요',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 프로젝트 선택 섹션
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '프로젝트',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _isCreatingNewProject = !_isCreatingNewProject;
                            });
                          },
                          icon: Icon(_isCreatingNewProject
                              ? Icons.folder_open
                              : Icons.folder),
                          label: Text(_isCreatingNewProject
                              ? '기존 프로젝트 선택'
                              : '새 프로젝트 만들기'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isCreatingNewProject) ...[
                      TextField(
                        controller: _newProjectTitleController,
                        decoration: const InputDecoration(
                          labelText: '프로젝트 제목',
                          hintText: '새 프로젝트의 제목을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _newProjectDescriptionController,
                        decoration: const InputDecoration(
                          labelText: '프로젝트 설명',
                          hintText: '프로젝트에 대한 설명을 입력하세요',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                    ] else
                      StreamBuilder<List<DocumentSnapshot>>(
                        stream: _firebaseService.getProjects(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Text('Error: ${snapshot.error}');
                          }

                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          final projects = snapshot.data!;
                          if (projects.isEmpty) {
                            return const Text('프로젝트가 없습니다. 새 프로젝트를 만들어주세요.');
                          }

                          return DropdownButtonFormField<String>(
                            value: _selectedProjectId,
                            decoration: const InputDecoration(
                              labelText: '프로젝트 선택',
                              border: OutlineInputBorder(),
                            ),
                            items: projects.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return DropdownMenuItem(
                                value: doc.id,
                                child: Text(data['title'] ?? ''),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedProjectId = value;
                              });
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveIdea,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
          child: const Text('아이디어 저장'),
        ),
      ),
    );
  }
}
