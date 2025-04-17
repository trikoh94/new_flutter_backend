import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import '../../models/idea.dart';

class IdeaCard extends StatelessWidget {
  final DocumentSnapshot idea;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddToMindMap;
  final VoidCallback? onShare;
  final VoidCallback? onExport;

  const IdeaCard({
    super.key,
    required this.idea,
    required this.onEdit,
    required this.onDelete,
    required this.onAddToMindMap,
    this.onShare,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    final data = idea.data() as Map<String, dynamic>;
    final ideaModel = Idea.fromMap(data);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ideaModel.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.edit,
                    onPressed: onEdit,
                    tooltip: 'Edit Idea',
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    context,
                    icon: Icons.delete,
                    onPressed: onDelete,
                    tooltip: 'Delete Idea',
                    color: Colors.red,
                  ),
                  if (onShare != null) ...[
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon:
                          ideaModel.isShared ? Icons.public : Icons.public_off,
                      onPressed: onShare!,
                      tooltip: ideaModel.isShared ? 'Unshare' : 'Share',
                      color: ideaModel.isShared ? Colors.green : Colors.grey,
                    ),
                  ],
                  if (onExport != null) ...[
                    const SizedBox(width: 8),
                    _buildActionButton(
                      context,
                      icon: Icons.download,
                      onPressed: onExport!,
                      tooltip: 'Export',
                      color: Colors.blue,
                    ),
                  ],
                ],
              ),
              if (ideaModel.description.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  ideaModel.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Created: ${_formatDate(ideaModel.createdAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  ElevatedButton.icon(
                    onPressed: onAddToMindMap,
                    icon: const Icon(Icons.account_tree),
                    label: const Text('Add to Mind Map'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.1),
                      foregroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    Color? color,
  }) {
    return IconButton(
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: color?.withOpacity(0.1),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class IdeaCardShimmer extends StatelessWidget {
  const IdeaCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              height: 16,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 16,
              width: 200,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
