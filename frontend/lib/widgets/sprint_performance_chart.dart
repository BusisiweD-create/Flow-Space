import 'package:flutter/material.dart';

class SprintPerformanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> sprints;

  const SprintPerformanceChart({super.key, required this.sprints});

  @override
  Widget build(BuildContext context) {
    if (sprints.isEmpty) {
      return const Center(child: Text('No sprint data'));
    }
    return ListView.builder(
      itemCount: sprints.length,
      itemBuilder: (context, index) {
        final sprint = sprints[index];
        final name = sprint['name']?.toString() ?? 'Sprint';
        final planned = _toInt(sprint['planned_points'] ?? sprint['committed_points']);
        final completed = _toInt(sprint['completed_points']);
        final ratio = planned > 0 ? (completed / planned).clamp(0.0, 1.0) : 0.0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: ratio,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(_colorForRatio(ratio)),
              ),
              const SizedBox(height: 4),
              Text('${(ratio * 100).toStringAsFixed(1)}% ($completed/$planned)'),
            ],
          ),
        );
      },
    );
  }

  int _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? 0;
    return 0;
  }

  Color _colorForRatio(double r) {
    if (r >= 1.0) return Colors.green;
    if (r >= 0.8) return Colors.blue;
    if (r >= 0.5) return Colors.orange;
    return Colors.red;
  }
}