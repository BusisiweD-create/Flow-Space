import 'package:flutter/material.dart';
import '../services/backend_api_service.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final BackendApiService _backend = BackendApiService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = false;
  String? _error;
  
  String _actorLabel(Map<String, dynamic> log) {
    String? pick(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    Map<String, dynamic>? pickMap(dynamic v) {
      if (v == null) return null;
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return Map<String, dynamic>.from(v);
      return null;
    }

    final user = pickMap(log['user']) ?? pickMap(log['actor']) ?? pickMap(log['performed_by']);
    final email = pick(log['user_email']) ?? pick(log['userEmail']) ?? pick(log['actor_email']) ?? pick(log['actorEmail']) ?? pick(user?['email']);
    final name = pick(log['actor']) ?? pick(user?['name']) ?? pick(user?['full_name']) ?? pick(user?['fullName']);
    final id = pick(log['user_id']) ?? pick(log['userId']) ?? pick(log['actor_id']) ?? pick(log['actorId']) ?? pick(user?['id']);
    return email ?? name ?? (id != null ? 'User $id' : 'System');
  }

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final resp = await _backend.getRealAuditLogs(skip: 0, limit: 200);
      if (resp.isSuccess && resp.data != null) {
        final raw = resp.data;
        final List<dynamic> items = raw is Map
            ? (raw['audit_logs'] ?? raw['items'] ?? raw['logs'] ?? raw['data'] ?? [])
            : (raw is List ? raw : []);
        setState(() {
          _logs = items.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
        });
      } else {
        setState(() {
          _logs = [];
          _error = resp.error ?? 'Failed to load audit logs';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load audit logs';
        _logs = [];
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Audit Logs'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(onPressed: _loadLogs, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : (_error != null
              ? Center(child: Text(_error!))
              : (_logs.isEmpty
                  ? const Center(child: Text('No audit logs available'))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _logs.length,
                      itemBuilder: (context, index) {
                        final log = _logs[index];
                        final action = (log['action'] ?? log['event'] ?? log['type'] ?? 'Log').toString();
                        final actor = _actorLabel(log);
                        final createdAt = log['created_at']?.toString() ?? '';
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Theme.of(context).dividerColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.receipt_long, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text('$action • $actor')),
                                ],
                              ),
                              if (createdAt.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(createdAt, style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ],
                          ),
                        );
                      },
                    ))),
    );
  }
}

