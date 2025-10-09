// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ClientReviewScreen extends StatefulWidget {
  const ClientReviewScreen({super.key});

  @override
  State<ClientReviewScreen> createState() => _ClientReviewScreenState();
}

class _ClientReviewScreenState extends State<ClientReviewScreen> {
  final _changeRequestController = TextEditingController();
  
  List<Map<String, dynamic>> _sprints = [];
  List<Map<String, dynamic>> _signoffs = [];
  int? _selectedSprintId;
  bool _isLoading = false;
  
  @override
  void initState() {
    super.initState();
    _loadSprints();
  }
  
  Future<void> _loadSprints() async {
    final currentContext = context;
    try {
      final sprints = await ApiService.getSprints();
      if (mounted) {
        setState(() {
          _sprints = sprints;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error loading sprints: \$e')),
        );
      }
    }
  }
  
  Future<void> _loadSignoffsForSprint(int sprintId) async {
    final currentContext = context;
    setState(() {
      _isLoading = true;
    });
    
    try {
      final signoffs = await ApiService.getSignoffsBySprint(sprintId);
      if (mounted) {
        setState(() {
          _signoffs = signoffs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error loading sign-offs: \$e')),
        );
      }
    }
  }
  
  Future<void> _approveSignoff(int signoffId) async {
    final currentContext = context;
    try {
      await ApiService.approveSignoff(signoffId);
      
      // Create audit log for sign-off approval
      await ApiService.createAuditLog(
        entityType: 'signoff',
        entityId: signoffId,
        action: 'approve',
        userEmail: ApiService.getCurrentUserEmail(),
        userRole: ApiService.getCurrentUserRole(),
        entityName: 'Sign-off #$signoffId',
        newValues: {'status': 'approved'}, details: '',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Sign-off approved successfully!')),
        );
        
        // Reload sign-offs
        if (_selectedSprintId != null) {
          _loadSignoffsForSprint(_selectedSprintId!);
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error approving sign-off: \$e')),
        );
      }
    }
  }
  
  Future<void> _submitChangeRequest(int signoffId, String changeRequest) async {
    final currentContext = context;
    if (changeRequest.isEmpty) {
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Please provide change request details')),
      );
      return;
    }
    
    try {
      // Create audit log for the change request
      await ApiService.createAuditLog(
        entityType: 'signoff',
        entityId: signoffId,
        action: 'change_request',
        userEmail: ApiService.getCurrentUserEmail(),
        userRole: 'client',
        entityName: 'Sign-off #$signoffId',
        newValues: {'change_request': changeRequest}, details: '',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Change request submitted successfully!')),
        );
        
        _changeRequestController.clear();
        
        // Reload sign-offs
        if (_selectedSprintId != null) {
          _loadSignoffsForSprint(_selectedSprintId!);
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Error submitting change request: \$e')),
        );
      }
    }
  }
  
  void _showChangeRequestDialog(int signoffId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Submit Change Request'),
        content: TextField(
          controller: _changeRequestController,
          decoration: const InputDecoration(
            labelText: 'Change Request Details',
            border: OutlineInputBorder(),
          ),
          maxLines: 4,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _submitChangeRequest(signoffId, _changeRequestController.text);
              Navigator.pop(context);
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSignoffCard(Map<String, dynamic> signoff) {
    final isApproved = signoff['is_approved'] == true;
    final statusColor = isApproved ? Colors.green : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sign-off #${signoff['id']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Chip(
                  label: Text(
                    isApproved ? 'APPROVED' : 'PENDING',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  backgroundColor: statusColor,
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Text('Signer: ${signoff['signer_name']}'),
            Text('Email: ${signoff['signer_email']}'),
            
            if (signoff['comments'] != null && signoff['comments'].isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const Text('Comments:', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(signoff['comments']),
                ],
              ),
            
            const SizedBox(height: 16),
            
            if (!isApproved)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveSignoff(signoff['id']),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showChangeRequestDialog(signoff['id']),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.orange),
                      ),
                      child: const Text('Request Changes', style: TextStyle(color: Colors.orange)),
                    ),
                  ),
                ],
              ),
            
            if (isApproved)
              const Text(
                'This sign-off has been approved.',
                style: TextStyle(color: Colors.green, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Review Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sprint Selection
                  const Text(
                    'Select Sprint for Review',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _selectedSprintId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Sprint',
                      prefixIcon: Icon(Icons.timeline),
                    ),
                    items: _sprints.map((sprint) {
                      return DropdownMenuItem<int?>(
                        value: sprint['id'],
                        child: Text(sprint['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSprintId = value;
                      });
                      if (value != null) {
                        _loadSignoffsForSprint(value);
                      }
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Sign-offs List
                  if (_selectedSprintId != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sign-offs for Selected Sprint (\${_signoffs.length})',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        _signoffs.isEmpty
                            ? const Card(
                                child: Padding(
                                  padding: EdgeInsets.all(16.0),
                                  child: Text('No sign-offs found for this sprint.'),
                                ),
                              )
                            : Column(
                                children: _signoffs.map((signoff) {
                                  return _buildSignoffCard(signoff);
                                }).toList(),
                              ),
                      ],
                    ),
                  
                  if (_selectedSprintId == null)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('Please select a sprint to view sign-offs.'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
  
  @override
  void dispose() {
    _changeRequestController.dispose();
    super.dispose();
  }
}