import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

class CommunityScreen extends StatefulWidget {
  final String projectId;

  const CommunityScreen({
    super.key,
    required this.projectId,
  });

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _commentController = TextEditingController();
  String? _selectedIdeaId;

  Future<void> _addComment(String ideaId, {String? parentCommentId}) async {
    final user = _auth.currentUser;
    if (user == null || _commentController.text.isEmpty) return;

    final comment = {
      'id': const Uuid().v4(),
      'text': _commentController.text,
      'authorId': user.uid,
      'authorName': user.displayName ?? 'Anonymous',
      'createdAt': DateTime.now().toIso8601String(),
      'parentCommentId': parentCommentId,
      'likes': 0,
      'replies': [],
    };

    await _firestore
        .collection('shared_ideas')
        .doc(ideaId)
        .collection('comments')
        .doc(comment['id'] as String)
        .set(comment);

    _commentController.clear();
  }

  Future<void> _convertCommentToIdea(String ideaId, String commentId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get the comment
    final commentDoc = await _firestore
        .collection('shared_ideas')
        .doc(ideaId)
        .collection('comments')
        .doc(commentId)
        .get();

    if (!commentDoc.exists) return;

    final comment = commentDoc.data()!;

    // Create a new idea from the comment
    final newIdea = {
      'id': const Uuid().v4(),
      'title': 'Idea from comment',
      'description': comment['text'],
      'createdAt': DateTime.now().toIso8601String(),
      'connections': [ideaId],
      'sourceCommentId': commentId,
      'authorId': user.uid,
      'authorName': user.displayName ?? 'Anonymous',
    };

    // Add the new idea to the project
    await _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(newIdea['id'] as String)
        .set(newIdea);

    // Update the comment to mark it as converted
    await _firestore
        .collection('shared_ideas')
        .doc(ideaId)
        .collection('comments')
        .doc(commentId)
        .update({'convertedToIdea': true});
  }

  void _showComments(String ideaId) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Comments',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('shared_ideas')
                    .doc(ideaId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final comments = snapshot.data!.docs;
                  return SizedBox(
                    height: 300,
                    child: Column(
                      children: [
                        Expanded(
                          child: ListView.builder(
                            itemCount: comments.length,
                            itemBuilder: (context, index) {
                              final comment = comments[index].data()
                                  as Map<String, dynamic>;
                              return Card(
                                child: ListTile(
                                  title: Text(comment['text']),
                                  subtitle: Text(
                                    '${comment['authorName']} - ${DateTime.parse(comment['createdAt']).toString().split(' ')[0]}',
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (!(comment['convertedToIdea'] ??
                                          false))
                                        IconButton(
                                          icon: const Icon(
                                              Icons.lightbulb_outline),
                                          onPressed: () =>
                                              _convertCommentToIdea(
                                                  ideaId, comment['id']),
                                          tooltip: 'Convert to Idea',
                                        ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentController,
                                decoration: const InputDecoration(
                                  hintText: 'Add a comment...',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: () {
                                _addComment(ideaId);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _suggestConnection(String sharedIdeaId, String myIdeaId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Get the shared idea details
    final sharedIdeaDoc =
        await _firestore.collection('shared_ideas').doc(sharedIdeaId).get();

    if (!sharedIdeaDoc.exists) return;

    // Get the user's idea details
    final myIdeaDoc = await _firestore
        .collection('projects')
        .doc(widget.projectId)
        .collection('ideas')
        .doc(myIdeaId)
        .get();

    if (!myIdeaDoc.exists) return;

    // Create a connection suggestion
    await _firestore.collection('connection_suggestions').add({
      'sharedIdeaId': sharedIdeaId,
      'myIdeaId': myIdeaId,
      'suggestedBy': user.uid,
      'suggestedByName': user.displayName ?? 'Anonymous',
      'status': 'pending', // pending, accepted, rejected
      'createdAt': DateTime.now().toIso8601String(),
      'sharedIdeaTitle': sharedIdeaDoc.data()?['title'],
      'myIdeaTitle': myIdeaDoc.data()?['title'],
    });
  }

  void _showConnectionSuggestions(String sharedIdeaId) {
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
              .toList();

          return AlertDialog(
            title: const Text('Suggest Connection'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: ideas.length,
                itemBuilder: (context, index) {
                  final idea = ideas[index];
                  return ListTile(
                    title: Text(idea['title']),
                    subtitle: Text(idea['description']),
                    trailing: IconButton(
                      icon: const Icon(Icons.add_link),
                      onPressed: () {
                        _suggestConnection(sharedIdeaId, idea['id']);
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
        title: const Text('Community'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('shared_ideas')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final ideas = snapshot.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: ideas.length,
            itemBuilder: (context, index) {
              final idea = ideas[index].data() as Map<String, dynamic>;
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            child: Text(idea['authorName']?[0] ?? '?'),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                idea['authorName'] ?? 'Anonymous',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                idea['projectName'] ?? 'Unknown Project',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        idea['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(idea['description'] ?? ''),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // TODO: Implement like functionality
                            },
                            icon: const Icon(Icons.favorite_border),
                            label: Text('${idea['likes'] ?? 0}'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () => _showComments(ideas[index].id),
                            icon: const Icon(Icons.comment_outlined),
                            label: Text('${idea['comments']?.length ?? 0}'),
                          ),
                          const SizedBox(width: 8),
                          TextButton.icon(
                            onPressed: () =>
                                _showConnectionSuggestions(ideas[index].id),
                            icon: const Icon(Icons.add_link),
                            label: const Text('Connect'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
