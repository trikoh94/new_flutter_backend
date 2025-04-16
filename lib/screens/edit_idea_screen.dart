import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../widgets/idea_edit_form.dart';

class EditIdeaScreen extends StatefulWidget {
  final String projectId;
  final String ideaId;

  const EditIdeaScreen({
    super.key,
    required this.projectId,
    required this.ideaId,
  });

  @override
  State<EditIdeaScreen> createState() => _EditIdeaScreenState();
}

class _EditIdeaScreenState extends State<EditIdeaScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIdea();
  }

  Future<void> _loadIdea() async {
    final doc = await _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(widget.ideaId)
        .get();

    if (doc.exists) {
      final data = doc.data()!;
      _titleController.text = data['title'] as String;
      _descriptionController.text = data['description'] as String;
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateIdea() async {
    if (_titleController.text.isEmpty) return;

    await _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(widget.ideaId)
        .update({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'updatedAt': DateTime.now().toIso8601String(),
    });

    if (mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Idea'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : IdeaEditForm(
              titleController: _titleController,
              descriptionController: _descriptionController,
              onSave: _updateIdea,
            ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
