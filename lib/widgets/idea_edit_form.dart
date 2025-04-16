import 'package:flutter/material.dart';

class IdeaEditForm extends StatelessWidget {
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final VoidCallback onSave;
  final String saveButtonText;

  const IdeaEditForm({
    super.key,
    required this.titleController,
    required this.descriptionController,
    required this.onSave,
    this.saveButtonText = 'Save Changes',
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: titleController,
            decoration: const InputDecoration(
              labelText: 'Idea Title',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: descriptionController,
            decoration: const InputDecoration(
              labelText: 'Idea Description',
              border: OutlineInputBorder(),
            ),
            maxLines: 5,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onSave,
            child: Text(saveButtonText),
          ),
        ],
      ),
    );
  }
}
