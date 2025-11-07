// ignore_for_file: use_build_context_synchronously, prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

final repositoryProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  return ApiService.getSignoffsBySprint(0); // Get all signoffs
});

class RepositoryScreen extends ConsumerStatefulWidget {
  const RepositoryScreen({super.key});

  @override
  ConsumerState<RepositoryScreen> createState() => _RepositoryScreenState();
}

class _RepositoryScreenState extends ConsumerState<RepositoryScreen> {
  int _selectedFilter = 0; // 0: All, 1: Approved, 2: Pending
  String _searchQuery = '';
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      // Load more data when scrolled to bottom
      ref.invalidate(repositoryProvider);
    }
  }

  List<Map<String, dynamic>> _filterSignoffs(List<Map<String, dynamic>> signoffs) {
    var filtered = signoffs;
    
    // Apply status filter
    if (_selectedFilter == 1) {
      filtered = filtered.where((signoff) => signoff['is_approved'] == true).toList();
    } else if (_selectedFilter == 2) {
      filtered = filtered.where((signoff) => signoff['is_approved'] == false).toList();
    }
    
    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((signoff) {
        final signerName = signoff['signer_name']?.toString().toLowerCase() ?? '';
        final signerEmail = signoff['signer_email']?.toString().toLowerCase() ?? '';
        final comments = signoff['comments']?.toString().toLowerCase() ?? '';
        final sprintName = signoff['sprint_name']?.toString().toLowerCase() ?? '';
        
        return signerName.contains(_searchQuery.toLowerCase()) ||
               signerEmail.contains(_searchQuery.toLowerCase()) ||
               comments.contains(_searchQuery.toLowerCase()) ||
               sprintName.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final signoffsAsync = ref.watch(repositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Signed Reports Repository'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(repositoryProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search signoffs...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedFilter == 0,
                        onSelected: (_) => setState(() => _selectedFilter = 0),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Approved'),
                        selected: _selectedFilter == 1,
                        onSelected: (_) => setState(() => _selectedFilter = 1),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending'),
                        selected: _selectedFilter == 2,
                        onSelected: (_) => setState(() => _selectedFilter = 2),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Signoffs List
          Expanded(
            child: signoffsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading signoffs: $error'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(repositoryProvider),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
              data: (signoffs) {
                final filteredSignoffs = _filterSignoffs(signoffs);
                
                if (filteredSignoffs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.folder_open, size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty ? 'No signoffs found' : 'No matching signoffs',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Signed reports will appear here once created.'
                              : 'Try a different search term or filter.',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
                
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(repositoryProvider),
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredSignoffs.length,
                    itemBuilder: (context, index) {
                      final signoff = filteredSignoffs[index];
                      return _SignoffCard(signoff: signoff);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SignoffCard extends StatelessWidget {
  final Map<String, dynamic> signoff;

  const _SignoffCard({required this.signoff});

  @override
  Widget build(BuildContext context) {
    final isApproved = signoff['is_approved'] == true;
    final signoffDate = signoff['created_at'] != null
        ? DateTime.parse(signoff['created_at'])
        : null;
    final formattedDate = signoffDate != null
        ? DateFormat('MMM dd, yyyy - HH:mm').format(signoffDate)
        : 'Unknown date';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    isApproved ? 'APPROVED' : 'PENDING',
                    style: TextStyle(
                      color: isApproved ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: isApproved ? Colors.green : Colors.orange,
                ),
                Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Signer Information
            Text(
              'Signed by: ${signoff['signer_name'] ?? 'Unknown'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            
            if (signoff['signer_email'] != null) ...[
              const SizedBox(height: 4),
              Text(
                signoff['signer_email'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Sprint Information
            if (signoff['sprint_name'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Sprint: ${signoff['sprint_name']}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Comments
            if (signoff['comments'] != null && signoff['comments'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Comments:',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 4),
              Text(
                signoff['comments'],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            
            // Actions
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // View detailed report
                    _showSignoffDetails(context, signoff);
                  },
                  icon: const Icon(Icons.visibility),
                  label: const Text('View Details'),
                ),
                const SizedBox(width: 8),
                if (!isApproved)
                  ElevatedButton.icon(
                    onPressed: () {
                      // Approve action
                      _approveSignoff(context, signoff);
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSignoffDetails(BuildContext context, Map<String, dynamic> signoff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Signoff Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signer: ${signoff['signer_name'] ?? 'Unknown'}'),
              Text('Email: ${signoff['signer_email'] ?? 'N/A'}'),
              Text('Status: ${signoff['is_approved'] == true ? 'Approved' : 'Pending'}'),
              if (signoff['sprint_name'] != null) Text('Sprint: ${signoff['sprint_name']}'),
              if (signoff['comments'] != null) Text('Comments: ${signoff['comments']}'),
              if (signoff['created_at'] != null)
                Text('Created: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.parse(signoff['created_at']))}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _approveSignoff(BuildContext context, Map<String, dynamic> signoff) async {
    final signoffId = signoff['id'];
    if (signoffId == null) return;

    final currentContext = context;
    
    try {
      final result = await ApiService.approveSignoff(signoffId);
      if (result != null && currentContext.mounted) {
        // Create audit log for sign-off approval
        var ref;
        await ApiService.createAuditLog(
          entityType: 'signoff',
          entityId: signoffId,
          action: 'approve',
          userEmail: ref.read(currentUserProvider).email,
          userRole: ref.read(currentUserProvider).role,
          entityName: 'Sign-off #$signoffId',
          newValues: {'status': 'approved'}, details: '',
        );
        
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Signoff approved successfully')),
        );
        // Refresh the list
        // ref.invalidate(repositoryProvider);
      }
    } catch (e) {
      if (currentContext.mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(content: Text('Error approving signoff: $e')),
        );
      }
    }
  }
}

extension on _SignoffCard {
  get currentUserProvider => null;
}