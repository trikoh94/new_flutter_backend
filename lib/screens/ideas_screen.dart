import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _projectName;
  String? _selectedIdeaId;

  @override
  void initState() {
    super.initState();
    _loadProjectName();
  }

  Future<void> _loadProjectName() async {
    final doc =
        await _firestore.collection('projects').doc(widget.projectId).get();
    if (doc.exists) {
      setState(() {
        _projectName = doc.data()?['name'] as String?;
      });
    }
  }

  Future<void> _createIdea() async {
    if (_ideaTitleController.text.isEmpty) return;

    final idea = {
      'id': const Uuid().v4(),
      'title': _ideaTitleController.text,
      'description': _ideaDescriptionController.text,
      'createdAt': DateTime.now().toIso8601String(),
      'connections': [],
    };

    await _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(idea['id'] as String)
        .set(idea);

    _ideaTitleController.clear();
    _ideaDescriptionController.clear();
  }

  Future<void> _shareIdea(Map<String, dynamic> idea) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final sharedIdea = {
      ...idea,
      'authorId': user.uid,
      'authorName': user.displayName ?? 'Anonymous',
      'projectId': widget.projectId,
      'projectName': _projectName,
      'sharedAt': DateTime.now().toIso8601String(),
      'likes': 0,
      'comments': [],
    };

    await _firestore.collection('shared_ideas').add(sharedIdea);
  }

  Future<void> _connectIdeas(String sourceId, String targetId) async {
    final sourceRef = _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(sourceId);

    final targetRef = _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(targetId);

    await _firestore.runTransaction((transaction) async {
      final sourceDoc = await transaction.get(sourceRef);
      final targetDoc = await transaction.get(targetRef);

      if (!sourceDoc.exists || !targetDoc.exists) return;

      final sourceConnections =
          List<String>.from(sourceDoc.data()?['connections'] ?? []);
      final targetConnections =
          List<String>.from(targetDoc.data()?['connections'] ?? []);

      if (!sourceConnections.contains(targetId)) {
        sourceConnections.add(targetId);
        transaction.update(sourceRef, {'connections': sourceConnections});
      }

      if (!targetConnections.contains(sourceId)) {
        targetConnections.add(sourceId);
        transaction.update(targetRef, {'connections': targetConnections});
      }
    });
  }

  void _showConnectionDialog(Map<String, dynamic> sourceIdea) {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('projects')
            .doc(widget.projectId)
            .collection('ideas')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ideas = snapshot.data!.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .where((idea) => idea['id'] != sourceIdea['id'])
              .toList();

          return AlertDialog(
            title: const Text('Connect with Idea'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ideas.length,
                itemBuilder: (context, index) {
                  final idea = ideas[index];
                  final isConnected =
                      (sourceIdea['connections'] as List<dynamic>?)
                              ?.contains(idea['id']) ??
                          false;

                  return ListTile(
                    title: Text(idea['title']),
                    subtitle: Text(idea['description']),
                    trailing: IconButton(
                      icon: Icon(
                        isConnected ? Icons.link : Icons.link_off,
                        color: isConnected ? Colors.blue : Colors.grey,
                      ),
                      onPressed: () {
                        if (isConnected) {
                          // TODO: Implement disconnect functionality
                        } else {
                          _connectIdeas(sourceIdea['id'], idea['id']);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_projectName ?? 'Ideas'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_tree),
            onPressed: () => context.push('/mind-map/${widget.projectId}'),
            tooltip: 'View Mind Map',
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => context.push('/community'),
            tooltip: 'View Community',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Create Idea Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Add New Idea',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ideaTitleController,
                      decoration: const InputDecoration(
                        labelText: 'Idea Title',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _ideaDescriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Idea Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _createIdea,
                      child: const Text('Add Idea'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Ideas List
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('projects')
                    .doc(widget.projectId)
                    .collection('ideas')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final ideas = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: ideas.length,
                    itemBuilder: (context, index) {
                      final idea = ideas[index].data() as Map<String, dynamic>;
                      final connections =
                          List<String>.from(idea['connections'] ?? []);

                      return Card(
                        child: ListTile(
                          title: Text(idea['title']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(idea['description']),
                              if (connections.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Connected with ${connections.length} ideas',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => context.push(
                                  '/projects/${widget.projectId}/ideas/${idea['id']}/edit',
                                ),
                                tooltip: 'Edit Idea',
                              ),
                              IconButton(
                                icon: const Icon(Icons.share),
                                onPressed: () => _shareIdea(idea),
                                tooltip: 'Share to Community',
                              ),
                              IconButton(
                                icon: const Icon(Icons.link),
                                onPressed: () => _showConnectionDialog(idea),
                                tooltip: 'Connect Ideas',
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
    _ideaTitleController.dispose();
    _ideaDescriptionController.dispose();
    super.dispose();
  }
}
