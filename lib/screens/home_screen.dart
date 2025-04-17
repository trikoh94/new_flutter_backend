import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firebase_service.dart';
import '../widgets/ideas/idea_card.dart';
import '../widgets/ideas/quick_actions_bar.dart';
import '../widgets/common/error_view.dart';
import '../widgets/common/empty_state_view.dart';
import '../screens/portfolio_screen.dart';
import '../screens/community_screen.dart';
import '../models/project_model.dart';
import 'dart:convert';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  int _selectedIndex = 0;
  static const int _ideasPerPage = 10;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  List<DocumentSnapshot> _ideas = [];
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  final _projectTitleController = TextEditingController();
  final _projectDescriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialIdeas();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _projectTitleController.dispose();
    _projectDescriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialIdeas() async {
    try {
      final snapshot = await _firebaseService.getPaginatedIdeas(_ideasPerPage);
      if (!mounted) return;

      setState(() {
        _ideas = snapshot?.docs ?? [];
        _lastDocument = _ideas.isNotEmpty ? _ideas.last : null;
        _hasMore = _ideas.length == _ideasPerPage;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load ideas: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadInitialIdeas,
          ),
        ),
      );
    }
  }

  Future<void> _loadMoreIdeas() async {
    if (!_hasMore || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final snapshot = await _firebaseService.getPaginatedIdeas(
        _ideasPerPage,
        startAfter: _lastDocument,
      );

      if (!mounted) return;

      setState(() {
        _ideas.addAll(snapshot?.docs ?? []);
        _lastDocument =
            snapshot?.docs.isNotEmpty == true ? snapshot!.docs.last : null;
        _hasMore = (snapshot?.docs.length ?? 0) == _ideasPerPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingMore = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load more ideas: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadMoreIdeas,
          ),
        ),
      );
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMoreIdeas();
    }
  }

  Future<void> _showCreateProjectDialog() async {
    context.push('/projects');
  }

  Future<void> _deleteIdea(String projectId, String ideaId, int index) async {
    try {
      await _firebaseService.deleteIdea(projectId, ideaId);
      if (!mounted) return;

      setState(() {
        _ideas.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Idea deleted')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete idea: $e'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () => _loadInitialIdeas(),
          ),
        ),
      );
    }
  }

  Future<void> _exportIdeas(bool sharedOnly) async {
    try {
      final exportData =
          await _firebaseService.exportIdeas(sharedOnly: sharedOnly);
      final jsonString = json.encode(exportData);

      // TODO: Implement platform-specific file saving
      // For web, we can use the browser's download functionality
      // For mobile, we can use the file system

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ideas exported successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to export ideas: $e')),
      );
    }
  }

  void _showExportDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Ideas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Export All Ideas'),
              onTap: () {
                Navigator.pop(context);
                _exportIdeas(false);
              },
            ),
            ListTile(
              title: const Text('Export Shared Ideas Only'),
              onTap: () {
                Navigator.pop(context);
                _exportIdeas(true);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAssignProjectDialog(Map<String, dynamic> idea) {
    if (idea == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Assign to Project'),
        content: StreamBuilder<List<ProjectModel>>(
          stream: _firebaseService.getProjects(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return ErrorView(
                message: snapshot.error.toString(),
                onRetry: () => setState(() {}),
              );
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final projects = snapshot.data!;
            if (projects.isEmpty) {
              return const Center(
                child: Text('No projects available. Create a project first.'),
              );
            }

            return SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: projects.length,
                itemBuilder: (context, index) {
                  final project = projects[index];
                  return ListTile(
                    title: Text(project.title),
                    onTap: () async {
                      try {
                        await _firebaseService.assignIdeaToProject(
                          idea['id'],
                          project.id,
                          project.title,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                        context.push('/mind-map/${project.id}');
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to assign idea: $e'),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ideation Hub'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.push('/profile'),
            tooltip: 'Profile',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _firebaseService.signOut();
              if (mounted) {
                context.go('/login');
              }
            },
            tooltip: 'Logout',
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildIdeasTab(),
          const PortfolioScreen(),
          const CommunityScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.lightbulb_outline),
            selectedIcon: Icon(Icons.lightbulb),
            label: 'Ideas',
            tooltip: 'View and manage your ideas',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Portfolio',
            tooltip: 'View your portfolio',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people),
            label: 'Community',
            tooltip: 'Connect with the community',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton.extended(
              onPressed: _showCreateProjectDialog,
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
              tooltip: 'Create a new project',
              heroTag: 'newProject',
            )
          : null,
    );
  }

  Widget _buildIdeasTab() {
    return Column(
      children: [
        const QuickActionsBar(),
        Expanded(
          child: _ideas.isEmpty && !_isLoadingMore
              ? const EmptyStateView(
                  icon: Icons.lightbulb_outline,
                  title: 'No Ideas Yet',
                  message: 'Start by creating a new idea or project',
                  actionLabel: 'Create New Idea',
                  actionRoute: '/quick-idea',
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _ideas.clear();
                    _lastDocument = null;
                    await _loadInitialIdeas();
                  },
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _ideas.length + (_isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _ideas.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(8.0),
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }

                      final ideaData =
                          _ideas[index].data() as Map<String, dynamic>;
                      return Dismissible(
                        key: Key(ideaData['id'] ?? ''),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Idea'),
                              content: const Text(
                                'Are you sure you want to delete this idea?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) {
                          _deleteIdea(
                            ideaData['projectId'] ?? 'unassigned',
                            ideaData['id'],
                            index,
                          );
                        },
                        child: IdeaCard(
                          idea: _ideas[index],
                          onEdit: () => context.push(
                            '/edit-idea/${ideaData['projectId'] ?? 'unassigned'}/${ideaData['id']}',
                          ),
                          onDelete: () => _deleteIdea(
                            ideaData['projectId'] ?? 'unassigned',
                            ideaData['id'],
                            index,
                          ),
                          onAddToMindMap: () {
                            if (ideaData['projectId'] != null) {
                              context
                                  .push('/mind-map/${ideaData['projectId']}');
                            } else {
                              _showAssignProjectDialog(ideaData);
                            }
                          },
                          onShare: () async {
                            try {
                              if (ideaData['isShared'] ?? false) {
                                await _firebaseService
                                    .unshareIdea(ideaData['id']);
                              } else {
                                await _firebaseService
                                    .shareIdea(ideaData['id']);
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Failed to update sharing status: $e'),
                                ),
                              );
                            }
                          },
                          onExport: _showExportDialog,
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}
