import 'package:flutter/material.dart';

class SprintReportScreen extends StatelessWidget {
  final List<Map<String, dynamic>> sprints;

  const SprintReportScreen({super.key, required this.sprints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprint Report'),
      ),
      body: ListView.builder(
        itemCount: sprints.length,
        itemBuilder: (context, index) {
          final sprint = sprints[index];
          final name = sprint['name']?.toString() ?? 'Sprint';
          final committed = _toInt(sprint['committed_points'] ?? sprint['committedPoints']);
          final completed = _toInt(sprint['completed_points'] ?? sprint['completedPoints']);
          final statusText = _statusText(sprint);
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8.0),
                  Text('Status: $statusText'),
                  const SizedBox(height: 8.0),
                  Text('Committed Points: $committed'),
                  const SizedBox(height: 8.0),
                  Text('Completed Points: $completed'),
                  const SizedBox(height: 8.0),
                  LinearProgressIndicator(
                    value: committed > 0 ? completed / committed : 0,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  String _statusText(Map<String, dynamic> s) {
    DateTime? start;
    DateTime? end;
    final sd = s['startDate'] ?? s['start_date'];
    final ed = s['endDate'] ?? s['end_date'];
    if (sd != null) {
      start = DateTime.tryParse(sd.toString());
    }
    if (ed != null) {
      end = DateTime.tryParse(ed.toString());
    }
    if (start != null && end != null) {
      final now = DateTime.now();
      if (now.isAfter(end)) {
        final committed = _toInt(s['committed_points'] ?? s['committedPoints']);
        final completed = _toInt(s['completed_points'] ?? s['completedPoints']);
        return completed >= committed && committed > 0 ? 'Completed' : 'Overdue';
      } else if (now.isAfter(start) && now.isBefore(end)) {
        return 'In Progress';
      }
    }
    return 'Not Started';
  }
}