// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Provider for audit trail state
final auditTrailProvider = StateNotifierProvider<AuditTrailNotifier, AuditTrailState>((ref) {
  return AuditTrailNotifier();
});

// Audit trail state
class AuditTrailState {
  final List<Map<String, dynamic>> logs;
  final bool isLoading;
  final String? error;
  final bool hasMore;
  final int currentPage;

  AuditTrailState({
    this.logs = const [],
    this.isLoading = false,
    this.error,
    this.hasMore = true,
    this.currentPage = 0,
  });

  AuditTrailState copyWith({
    List<Map<String, dynamic>>? logs,
    bool? isLoading,
    String? error,
    bool? hasMore,
    int? currentPage,
  }) {
    return AuditTrailState(
      logs: logs ?? this.logs,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Audit trail notifier
class AuditTrailNotifier extends StateNotifier<AuditTrailState> {
  AuditTrailNotifier() : super(AuditTrailState());

  Future<void> loadAuditLogs({bool refresh = false}) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final skip = refresh ? 0 : state.logs.length;
      final logs = await ApiService.getAuditLogs(skip: skip, limit: 50);
      
      state = state.copyWith(
        logs: refresh ? logs : [...state.logs, ...logs],
        isLoading: false,
        hasMore: logs.length == 50,
        currentPage: refresh ? 0 : state.currentPage + 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load audit logs: \$e',
      );
    }
  }

  Future<void> refresh() async {
    await loadAuditLogs(refresh: true);
  }

  Future<void> loadEntityAuditLogs(String entityType, int entityId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final logs = await ApiService.getAuditLogsForEntity(
        entityType: entityType,
        entityId: entityId,
      );
      
      state = state.copyWith(
        logs: logs,
        isLoading: false,
        hasMore: false,
        currentPage: 0,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load entity audit logs: \$e',
      );
    }
  }
}

class AuditTrailScreen extends ConsumerStatefulWidget {
  final String? entityType;
  final int? entityId;
  final String? entityName;

  const AuditTrailScreen({
    super.key,
    this.entityType,
    this.entityId,
    this.entityName,
  });

  @override
  ConsumerState<AuditTrailScreen> createState() => _AuditTrailScreenState();
}

class _AuditTrailScreenState extends ConsumerState<AuditTrailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadInitialData() {
    if (widget.entityType != null && widget.entityId != null) {
      ref.read(auditTrailProvider.notifier).loadEntityAuditLogs(
        widget.entityType!,
        widget.entityId!,
      );
    } else {
      ref.read(auditTrailProvider.notifier).loadAuditLogs(refresh: true);
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      final state = ref.read(auditTrailProvider);
      if (!state.isLoading && state.hasMore && 
          widget.entityType == null && widget.entityId == null) {
        ref.read(auditTrailProvider.notifier).loadAuditLogs();
      }
    }
  }

  Widget _buildAuditLogItem(Map<String, dynamic> log) {
    final timestamp = log['timestamp'] ?? log['created_at'] ?? '';
    final action = log['action']?.toString() ?? 'Unknown Action';
    final user = log['user'] ?? log['username'] ?? 'Unknown User';
    final details = log['details'] ?? log['description'] ?? '';
    final entityType = log['entity_type'] ?? '';
    final entityId = log['entity_id']?.toString() ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: _getActionIcon(action),
        title: Text(
          action,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (details.isNotEmpty) Text(details),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  user,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(width: 8),
                if (entityType.isNotEmpty && entityId.isNotEmpty)
                  Text(
                    '$entityType #$entityId',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[600],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(timestamp),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
        trailing: _getActionBadge(action),
      ),
    );
  }

  Icon _getActionIcon(String action) {
    final lowerAction = action.toLowerCase();
    
    if (lowerAction.contains('create') || lowerAction.contains('add')) {
      return const Icon(Icons.add_circle, color: Colors.green);
    } else if (lowerAction.contains('update') || lowerAction.contains('edit')) {
      return const Icon(Icons.edit, color: Colors.blue);
    } else if (lowerAction.contains('delete') || lowerAction.contains('remove')) {
      return const Icon(Icons.delete, color: Colors.red);
    } else if (lowerAction.contains('approve') || lowerAction.contains('accept')) {
      return const Icon(Icons.check_circle, color: Colors.green);
    } else if (lowerAction.contains('reject') || lowerAction.contains('deny')) {
      return const Icon(Icons.cancel, color: Colors.red);
    } else if (lowerAction.contains('sign') || lowerAction.contains('review')) {
      return const Icon(Icons.assignment_turned_in, color: Colors.orange);
    } else {
      return const Icon(Icons.history, color: Colors.grey);
    }
  }

  Widget _getActionBadge(String action) {
    final lowerAction = action.toLowerCase();
    Color color;
    
    if (lowerAction.contains('create') || lowerAction.contains('add')) {
      color = Colors.green;
    } else if (lowerAction.contains('update') || lowerAction.contains('edit')) {
      color = Colors.blue;
    } else if (lowerAction.contains('delete') || lowerAction.contains('remove')) {
      color = Colors.red;
    } else if (lowerAction.contains('approve') || lowerAction.contains('accept')) {
      color = Colors.green;
    } else if (lowerAction.contains('reject') || lowerAction.contains('deny')) {
      color = Colors.red;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha((0.1 * 255).round()),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        action.split(' ').take(2).join(' '),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        return timestamp;
      }
    }
    return timestamp?.toString() ?? 'Unknown time';
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: [
          FilterChip(
            label: const Text('All Actions'),
            selected: true,
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Create'),
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Update'),
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Delete'),
            onSelected: (_) {},
          ),
          const SizedBox(width: 8),
          FilterChip(
            label: const Text('Approvals'),
            onSelected: (_) {},
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auditState = ref.watch(auditTrailProvider);

    return Scaffold(
      appBar: AppBar(
        title: widget.entityName != null
            ? const Text('Audit Trail - \${widget.entityName}')
            : const Text('Audit Trail'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(auditTrailProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.entityType == null && widget.entityId == null)
            _buildFilterChips(),
          
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(auditTrailProvider.notifier).refresh();
              },
              child: _buildContent(auditState),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(AuditTrailState state) {
    if (state.isLoading && state.logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Error: \${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(auditTrailProvider.notifier).refresh();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.logs.isEmpty) {
      return const Center(
        child: Text('No audit logs found'),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      itemCount: state.logs.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= state.logs.length) {
          return state.hasMore
              ? const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                )
              : const SizedBox.shrink();
        }
        return _buildAuditLogItem(state.logs[index]);
      },
    );
  }
}