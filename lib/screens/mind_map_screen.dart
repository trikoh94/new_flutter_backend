import 'package:flutter/material.dart';
import '../models/idea.dart';
import '../services/firebase_service.dart';
import '../widgets/mind_map.dart';

class MindMapScreen extends StatefulWidget {
  final String projectId;

  const MindMapScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<MindMapScreen> createState() => _MindMapScreenState();
}

class _MindMapScreenState extends State<MindMapScreen> {
  final _firebaseService = FirebaseService();

  Future<void> _updateIdeaPosition(String ideaId, Offset position) async {
    try {
      await _firebaseService.updateIdeaPosition(
        widget.projectId,
        ideaId,
        position.dx,
        position.dy,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update idea position: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showIdeaDetails(BuildContext context, Idea idea) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                idea.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                idea.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              const Text(
                '연결된 아이디어',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              FutureBuilder<List<Idea>>(
                future: Future.wait(
                  idea.connectedIdeas.map(
                      (id) => _firebaseService.getIdea(widget.projectId, id)),
                ).then((ideas) => ideas.whereType<Idea>().toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Text('연결된 아이디어가 없습니다.');
                  }
                  return Container(
                    height: 200,
                    child: ListView.builder(
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        final connectedIdea = snapshot.data![index];
                        return Card(
                          child: ListTile(
                            title: Text(connectedIdea.title),
                            subtitle: Text(
                              connectedIdea.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              Navigator.pop(context);
                              _showIdeaDetails(context, connectedIdea);
                            },
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('닫기'),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: 아이디어 수정 기능 구현
                    },
                    child: const Text('수정'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mind Map'),
      ),
      body: StreamBuilder<List<Idea>>(
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
            return const Center(
              child: Text('No ideas to display. Add some ideas first!'),
            );
          }

          return MindMap(
            ideas: ideas,
            projectId: widget.projectId,
            onIdeaMoved: _updateIdeaPosition,
            onIdeaTapped: (idea) => _showIdeaDetails(context, idea),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final screenSize = MediaQuery.of(context).size;
          final idea = Idea.create(
            title: 'Sample Idea',
            description: 'This is a sample idea for testing.',
          ).copyWith(
            x: screenSize.width / 2,
            y: screenSize.height / 2,
          );
          try {
            await _firebaseService.createIdea(idea, widget.projectId);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Sample idea created successfully')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
