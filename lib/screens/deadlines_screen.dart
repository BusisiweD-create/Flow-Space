import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/flownet_theme.dart';
import '../services/api_service.dart';

class DeadlinesScreen extends ConsumerStatefulWidget {
  const DeadlinesScreen({super.key});

  @override
  ConsumerState<DeadlinesScreen> createState() => _DeadlinesScreenState();
}

class _DeadlinesScreenState extends ConsumerState<DeadlinesScreen> {
  bool _isLoading = false;
  String? _error;
  String _filter = 'all';
  String _search = '';
  List<Map<String, dynamic>> _deliverables = [];

  @override
  void initState() {
    super.initState();
    _loadDeliverables();
  }

  Future<void> _loadDeliverables() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final items = await ApiService.getDeliverables();
      setState(() {
        _deliverables = items;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load deadlines';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference > 0) return 'In $difference days';
    return 'Overdue';
  }

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  List<Map<String, dynamic>> _filteredDeadlines() {
    final now = DateTime.now();
    final items = _deliverables.map((d) {
      final due = _parseDate(d['due_date']) ?? _parseDate(d['dueDate']) ?? _parseDate(d['deadline']);
      final title = (d['title'] ?? '').toString();
      final project = (d['project'] ?? d['project_name'] ?? '').toString();
      final priority = (d['priority'] ?? 'medium').toString();
      final status = (d['status'] ?? '').toString();
      return {
        'title': title,
        'project': project,
        'priority': priority,
        'status': status,
        'due': due,
      };
    }).where((m) {
      final due = m['due'] as DateTime?;
      if (due == null) return false;
      if (_search.isNotEmpty) {
        final s = _search.toLowerCase();
        final t = (m['title'] as String).toLowerCase();
        final p = (m['project'] as String).toLowerCase();
        if (!(t.contains(s) || p.contains(s))) return false;
      }
      if (_filter == 'overdue') return due.isBefore(now);
      if (_filter == 'today') {
        final diff = due.difference(now).inDays;
        return diff == 0;
      }
      if (_filter == 'upcoming') return due.isAfter(now);
      return true;
    }).toList();
    items.sort((a, b) {
      final da = a['due'] as DateTime;
      final db = b['due'] as DateTime;
      return da.compareTo(db);
    });
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final items = _filteredDeadlines();
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const Text('All Deadlines'),
        backgroundColor: FlownetColors.graphiteGray,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDeliverables,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDeliverables,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search deadlines',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        setState(() {
                          _search = v;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  DropdownButton<String>(
                    value: _filter,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('All')),
                      DropdownMenuItem(value: 'today', child: Text('Today')),
                      DropdownMenuItem(value: 'upcoming', child: Text('Upcoming')),
                      DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() {
                        _filter = v;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_error != null)
                Expanded(
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(color: FlownetColors.pureWhite),
                    ),
                  ),
                )
              else if (items.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(
                      'No deadlines found',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(color: FlownetColors.pureWhite),
                    ),
                  ),
                )
              else if (_filter == 'all')
                Expanded(
                  child: ListView(
                    children: () {
                      final now = DateTime.now();
                      final overdue = items.where((i) => (i['due'] as DateTime).isBefore(now)).toList();
                      final today = items.where((i) => (i['due'] as DateTime).difference(now).inDays == 0).toList();
                      final upcoming = items.where((i) {
                        final d = i['due'] as DateTime;
                        final diff = d.difference(now).inDays;
                        return diff > 0;
                      }).toList();
                      final sections = [
                        {'label': 'Overdue', 'items': overdue, 'color': Colors.red},
                        {'label': 'Today', 'items': today, 'color': Colors.orange},
                        {'label': 'Upcoming', 'items': upcoming, 'color': Colors.green},
                      ];
                      final children = <Widget>[];
                      for (final s in sections) {
                        final list = (s['items'] as List).cast<Map<String, dynamic>>();
                        if (list.isEmpty) continue;
                        children.add(
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                s['label'] as String,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: FlownetColors.pureWhite,
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (s['color'] as Color).withAlpha(25),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: s['color'] as Color),
                                ),
                                child: Text(
                                  list.length.toString(),
                                  style: TextStyle(color: s['color'] as Color, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                        children.add(const SizedBox(height: 8));
                        for (final item in list) {
                          final due = item['due'] as DateTime;
                          final pr = item['priority'] as String;
                          final status = (item['status'] as String).toLowerCase();
                          final statusColor = () {
                            if (status.contains('completed') || status.contains('approved') || status == 'done') return Colors.green;
                            if (status.contains('in') && status.contains('progress')) return Colors.blue;
                            if (status.contains('review') || status.contains('pending')) return Colors.orange;
                            return Colors.grey;
                          }();
                          children.add(
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey[300]!),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: _priorityColor(pr),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                fontWeight: FontWeight.w500,
                                                color: FlownetColors.pureWhite,
                                              ),
                                        ),
                                        Text(
                                          (item['project'] as String).isNotEmpty ? item['project'] as String : 'Project',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _formatDate(due),
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: _priorityColor(pr),
                                            ),
                                      ),
                                      Container(
                                        margin: const EdgeInsets.only(top: 4),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withAlpha(25),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          (item['status'] as String).isNotEmpty ? item['status'] as String : 'Pending',
                                          style: TextStyle(
                                            color: statusColor,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                      }
                      return children;
                    }(),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final due = item['due'] as DateTime;
                      final pr = item['priority'] as String;
                      final status = (item['status'] as String).toLowerCase();
                      final statusColor = () {
                        if (status.contains('completed') || status.contains('approved') || status == 'done') return Colors.green;
                        if (status.contains('in') && status.contains('progress')) return Colors.blue;
                        if (status.contains('review') || status.contains('pending')) return Colors.orange;
                        return Colors.grey;
                      }();
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _priorityColor(pr),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title'] as String,
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontWeight: FontWeight.w500,
                                          color: FlownetColors.pureWhite,
                                        ),
                                  ),
                                  Text(
                                    (item['project'] as String).isNotEmpty ? item['project'] as String : 'Project',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.grey[600],
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatDate(due),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _priorityColor(pr),
                                      ),
                                ),
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: statusColor),
                                  ),
                                  child: Text(
                                    (item['status'] as String).isNotEmpty ? item['status'] as String : 'Pending',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}