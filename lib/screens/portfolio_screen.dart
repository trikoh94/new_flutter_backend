import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/project_model.dart';
import '../services/firebase_service.dart';
import '../services/connectivity_service.dart';
import '../widgets/project_card.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final ConnectivityService _connectivityService = ConnectivityService();

  @override
  void initState() {
    super.initState();
    _connectivityService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Project Portfolios'),
        actions: [
          StreamBuilder<ConnectivityStatus>(
            stream: _connectivityService.statusStream,
            builder: (context, snapshot) {
              final status = snapshot.data;
              if (status == null) return const SizedBox.shrink();

              return Row(
                children: [
                  if (!status.isOnline)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Icon(
                        Icons.cloud_off,
                        color: Colors.red,
                        size: 20,
                      ),
                    ),
                  if (status.isSyncing)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => context.push('/projects'),
                    tooltip: 'Create New Project',
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<ConnectivityStatus>(
        stream: _connectivityService.statusStream,
        builder: (context, snapshot) {
          final status = snapshot.data;
          final isOffline = status?.isOnline == false;

          return Column(
            children: [
              if (isOffline)
                Container(
                  color: Colors.orange.shade100,
                  padding: const EdgeInsets.all(8.0),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'You are offline. Changes will be saved locally.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Projects',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Each project can have its own portfolio of ideas and developments',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
              Expanded(
                child: StreamBuilder<List<ProjectModel>>(
                  stream: _firebaseService.getProjects(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    final projects = snapshot.data!;
                    if (projects.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.folder_open,
                              size: 64,
                              color: Colors.grey,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No projects yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Create a project to start building your portfolio',
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => context.push('/projects'),
                              icon: const Icon(Icons.add),
                              label: const Text('Create Project'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: projects.length,
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: ProjectCard(project: project),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
