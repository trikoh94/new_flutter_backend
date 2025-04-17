import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';

class ProjectCard extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final FirebaseService _firebaseService = FirebaseService();

  ProjectCard({
    super.key,
    required this.project,
    this.onEdit,
    this.onDelete,
  });

  Future<void> _launchUrl(String? urlString) async {
    if (urlString == null) return;

    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.blue;
      case 'on hold':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(
              project.title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.circle,
                      size: 8,
                      color: _getStatusColor(project.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      project.status,
                      style: TextStyle(
                        color: _getStatusColor(project.status),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.account_tree),
                  onPressed: () => context.push('/mind-map/${project.id}'),
                  tooltip: 'View Mind Map',
                ),
                IconButton(
                  icon: const Icon(Icons.auto_awesome),
                  onPressed: () => context.push('/ai/portfolio/${project.id}'),
                  tooltip: 'View Portfolio',
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit?.call();
                        break;
                      case 'delete':
                        onDelete?.call();
                        break;
                      case 'github':
                        _launchUrl(project.githubUrl);
                        break;
                      case 'demo':
                        _launchUrl(project.demoUrl);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    if (onEdit != null)
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit),
                            SizedBox(width: 8),
                            Text('Edit'),
                          ],
                        ),
                      ),
                    if (onDelete != null)
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    if (project.githubUrl != null)
                      const PopupMenuItem(
                        value: 'github',
                        child: Row(
                          children: [
                            Icon(Icons.code),
                            SizedBox(width: 8),
                            Text('View Code'),
                          ],
                        ),
                      ),
                    if (project.demoUrl != null)
                      const PopupMenuItem(
                        value: 'demo',
                        child: Row(
                          children: [
                            Icon(Icons.launch),
                            SizedBox(width: 8),
                            Text('View Demo'),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              spacing: 8,
              children: project.technologies
                  .map((tech) => Chip(
                        label: Text(tech),
                        backgroundColor:
                            Theme.of(context).colorScheme.surfaceVariant,
                      ))
                  .toList(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Portfolio',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                StreamBuilder<List<dynamic>>(
                  stream: _firebaseService.getIdeas(project.id),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const CircularProgressIndicator();
                    }

                    final ideas = snapshot.data!;
                    if (ideas.isEmpty) {
                      return const Text(
                        'No ideas in portfolio yet. Click the wand icon to generate ideas.',
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    return Column(
                      children: [
                        Text(
                          '${ideas.length} ideas in portfolio',
                          style: const TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              context.push('/ai/portfolio/${project.id}'),
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('View Portfolio'),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
