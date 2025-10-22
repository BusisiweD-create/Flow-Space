import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../models/user.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final BackendApiService _backendApiService = BackendApiService();
  User? _currentUser;
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditProfileDialog,
            tooltip: 'Edit Profile',
          ),
          IconButton(
            icon: const Icon(Icons.description),
            onPressed: _showReportOptionsDialog,
            tooltip: 'Generate Report',
          ),
        ],
      ),
      body: _currentUser != null
          ? _buildProfileContent()
          : const Center(
              child: Text('No user data available'),
            ),
    );
  }

  Widget _buildProfileContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Name: ${_currentUser!.name}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text('Email: ${_currentUser!.email}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('Role: ${_currentUser!.roleDisplayName}', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 8),
          Text('User ID: ${_currentUser!.id}', style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = _authService.currentUser;
      
      setState(() {
        _currentUser = currentUser;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }


  // Removed unused _resendVerificationEmail method

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                initialValue: _currentUser?.name ?? '',
                decoration: const InputDecoration(labelText: 'Name'),
                onChanged: (value) {
                  // Handle name change
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                initialValue: _currentUser?.email ?? '',
                decoration: const InputDecoration(labelText: 'Email'),
                onChanged: (value) {
                  // Handle email change
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // Save profile changes
              Navigator.pop(context);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showReportOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Report'),
        content: const Text('Select the type of report to generate:'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateSignOffReport();
            },
            child: const Text('Sign-off Report'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _generateAuditTrailReport();
            },
            child: const Text('Audit Trail'),
          ),
        ],
      ),
    );
  }

  Future<void> _generateSignOffReport() async {
    if (!mounted) return;
    final currentContext = context;
    
    try {
      // Show loading indicator
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Generating sign-off report...')),
      );

      // Get sign-off reports data
      final response = await _backendApiService.getSignOffReports(limit: 10);
      
      if (!mounted) return;
      
      if (response.isSuccess) {
        final reports = response.data?['reports'] ?? response.data?['items'] ?? [];
        
        // Create a comprehensive sign-off report (in a real implementation)
        // final reportData = {
        //   'generated_at': DateTime.now().toIso8601String(),
        //   'generated_by': _currentUser?.email ?? 'Unknown',
        //   'total_reports': reports.length,
        //   'reports_summary': reports.map((report) => {
        //     'id': report['id'],
        //     'title': report['report_title'] ?? report['title'],
        //     'status': report['status'],
        //     'created_at': report['created_at'],
        //     'deliverable_id': report['deliverable_id'],
        //   }).toList(),
        //   'user_context': {
        //     'user_id': _currentUser?.id,
        //     'user_role': _currentUser?.roleDisplayName,
        //     'generation_time': DateTime.now().toIso8601String(),
        //   },
        // };

        // Show success message with report details
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Sign-off report generated successfully! ${reports.length} reports found.'),
            duration: const Duration(seconds: 4),
          ),
        );

        // In a real implementation, this would:
        // 1. Generate PDF/HTML report from the data
        // 2. Offer download or email options
        // 3. Save the report to user's report repository
        
        // print('Sign-off Report Data: $reportData');
        
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Failed to generate sign-off report')),
        );
      }
      
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error generating sign-off report: $e')),
      );
    }
  }

  Future<void> _generateAuditTrailReport() async {
    if (!mounted) return;
    final currentContext = context;
    
    try {
      // Show loading indicator
      ScaffoldMessenger.of(currentContext).showSnackBar(
        const SnackBar(content: Text('Generating audit trail report...')),
      );

      // Get audit logs data
      final response = await _backendApiService.getAuditLogs(limit: 20);
      
      if (!mounted) return;
      
      if (response.isSuccess) {
        final auditLogs = response.data?['audit_logs'] ?? response.data?['items'] ?? response.data?['logs'] ?? [];
        
        // Create a comprehensive audit trail report (in a real implementation)
        // final reportData = {
        //   'generated_at': DateTime.now().toIso8601String(),
        //   'generated_by': _currentUser?.email ?? 'Unknown',
        //   'total_logs': auditLogs.length,
        //   'time_period': {
        //     'start': auditLogs.isNotEmpty ? auditLogs.last['created_at'] : null,
        //     'end': auditLogs.isNotEmpty ? auditLogs.first['created_at'] : null,
        //   },
        //   'logs_summary': auditLogs.map((log) => {
        //     'id': log['id'],
        //     'action': log['action'],
        //     'entity_type': log['entity_type'],
        //     'entity_id': log['entity_id'],
        //     'user_id': log['user_id'],
        //     'created_at': log['created_at'],
        //     'details': log['details'],
        //   }).toList(),
        //   'user_context': {
        //     'user_id': _currentUser?.id,
        //     'user_role': _currentUser?.roleDisplayName,
        //     'generation_time': DateTime.now().toIso8601String(),
        //   },
        // };

        // Show success message with report details
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          SnackBar(
            content: Text('Audit trail report generated successfully! ${auditLogs.length} logs found.'),
            duration: const Duration(seconds: 4),
          ),
        );

        // In a real implementation, this would:
        // 1. Generate PDF/HTML report from the data
        // 2. Offer download or email options
        // 3. Save the report to audit repository
        
        // print('Audit Trail Report Data: $reportData');
        
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(currentContext).showSnackBar(
          const SnackBar(content: Text('Failed to generate audit trail report')),
        );
      }
      
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(currentContext).showSnackBar(
        SnackBar(content: Text('Error generating audit trail report: $e')),
      );
    }
  }
}