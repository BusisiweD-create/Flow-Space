import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../services/sprint_database_service.dart';
import '../widgets/project_card.dart';

class ProjectsOverviewScreen extends StatefulWidget {
  const ProjectsOverviewScreen({super.key});

  @override
  State<ProjectsOverviewScreen> createState() => _ProjectsOverviewScreenState();
}

class _ProjectsOverviewScreenState extends State<ProjectsOverviewScreen> {
  final SprintDatabaseService _sprintService = SprintDatabaseService();
  final List<Map<String, dynamic>> _projects = [];
  bool _isLoading = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final projects = await _sprintService.getProjects();
      setState(() {
        _projects
          ..clear()
          ..addAll(projects);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _filteredProjects {
    if (_searchQuery.isEmpty) return _projects;
    final q = _searchQuery.toLowerCase();
    return _projects.where((p) {
      final name = (p['name'] ?? '').toString().toLowerCase();
      final key = (p['key'] ?? '').toString().toLowerCase();
      final client = (p['client_name'] ?? p['clientName'] ?? '').toString().toLowerCase();
      return name.contains(q) || key.contains(q) || client.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final projects = _filteredProjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProjects,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search projects by name, key, or client',
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : projects.isEmpty
                    ? const Center(child: Text('No projects found'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 1;
                          final width = constraints.maxWidth;
                          if (width > 1200) {
                            crossAxisCount = 4;
                          } else if (width > 900) {
                            crossAxisCount = 3;
                          } else if (width > 600) {
                            crossAxisCount = 2;
                          }
                          return GridView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              childAspectRatio: 1.6,
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                            ),
                            itemCount: projects.length,
                            itemBuilder: (context, index) {
                              final project = projects[index];
                              final id = project['id']?.toString();
                              return ProjectCard(
                                project: project,
                                isSelected: false,
                                onTap: () {
                                  final pid = id ?? project['key']?.toString();
                                  if (pid != null && pid.isNotEmpty) {
                                    context.push('/project-workspace/$pid');
                                  }
                                },
                                onEdit: () {
                                  final pid = id ?? project['key']?.toString();
                                  if (pid != null && pid.isNotEmpty) {
                                    context.push('/project-workspace/$pid');
                                  }
                                },
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>('/project-workspace/new');
          if (created == true) {
            await _loadProjects();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Project'),
      ),
      // ignore: deprecated_member_use
      backgroundColor: theme.colorScheme.background,
    );
  }
}

