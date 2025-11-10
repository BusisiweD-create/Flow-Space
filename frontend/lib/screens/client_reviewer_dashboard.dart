import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/sprint.dart';
import 'client_review_screen.dart';

class ClientReviewerDashboard extends StatefulWidget {
  const ClientReviewerDashboard({super.key});

  @override
  State<ClientReviewerDashboard> createState() => _ClientReviewerDashboardState();
}

class _ClientReviewerDashboardState extends State<ClientReviewerDashboard> {
  List<Sprint> _sprints = [];
  bool _isLoading = false;
  String? _selectedSprintId;

  @override
  void initState() {
    super.initState();
    _loadSprints();
  }

  Future<void> _loadSprints() async {
    setState(() => _isLoading = true);
    try {
      final sprints = await ApiService.getSprints();
      setState(() => _sprints = sprints);
    } catch (e) {
      // ignore: use_build_context_synchronously
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error loading sprints: \${e.toString()}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Reviewer Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadSprints,
            tooltip: 'Refresh Sprints',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.blue,
                            child: Icon(
                              Icons.verified_user,
                              size: 30,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Client Review Dashboard',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Review and approve sprint deliverables',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Sprint Selection
                  const Text(
                    'Select Sprint for Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    // ignore: deprecated_member_use
                    value: _selectedSprintId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Sprint',
                      prefixIcon: Icon(Icons.timeline),
                    ),
                    items: _sprints.map((sprint) {
                      return DropdownMenuItem<String?>(
                        value: sprint.id,
                        child: Text(sprint.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSprintId = value);
                    },
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  if (_selectedSprintId != null)
                    Column(
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ClientReviewScreen(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.reviews),
                          label: const Text('Review Sign-offs'),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to sprint report
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Sprint report functionality coming soon')),
                            );
                          },
                          icon: const Icon(Icons.assessment),
                          label: const Text('View Sprint Report'),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                        ),
                      ],
                    ),

                  if (_selectedSprintId == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Please select a sprint to begin review.'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}