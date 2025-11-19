import 'package:flutter/material.dart';

class DeliverableMapCard extends StatelessWidget {
  final Map<String, dynamic> deliverable;
  final VoidCallback? onTap;

  const DeliverableMapCard({super.key, required this.deliverable, this.onTap});

  @override
  Widget build(BuildContext context) {
    final title = deliverable['title']?.toString() ?? 'Untitled Deliverable';
    final description = deliverable['description']?.toString() ?? '';
    final status = deliverable['status']?.toString().toUpperCase() ?? 'PENDING';
    final color = _statusColor(deliverable['status']?.toString() ?? '');

    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Chip(
          label: Text(status),
          backgroundColor: color.withValues(alpha: 0.15),
          labelStyle: TextStyle(color: color),
        ),
        onTap: onTap,
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'submitted':
        return Colors.orange;
      case 'pending':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
