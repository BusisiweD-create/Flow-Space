import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  final List<NotificationItem> _notifications = [
    NotificationItem(
      id: '1',
      title: 'New Approval Request',
      description:
          'John Doe has requested approval for User Authentication System',
      date: DateTime.now().subtract(const Duration(minutes: 30)),
      isRead: false,
      type: NotificationType.approval,
    ),
    NotificationItem(
      id: '2',
      title: 'Sprint Completed',
      description: 'Sprint 3 has been completed successfully',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.sprint,
    ),
    NotificationItem(
      id: '3',
      title: 'File Uploaded',
      description: 'Alice Johnson uploaded project_design.pdf to repository',
      date: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
      type: NotificationType.repository,
    ),
    NotificationItem(
      id: '4',
      title: 'Deliverable Due',
      description: 'Database Schema Update deliverable is due tomorrow',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.deliverable,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Mark All as Read',
          ),
        ],
      ),
      body: Column(
        children: [
          // Notification stats
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatCard(
                  'Unread',
                  _notifications.where((n) => !n.isRead).length.toString(),
                  Colors.orange,
                ),
                _buildStatCard(
                  'Total',
                  _notifications.length.toString(),
                  Colors.blue,
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: _notifications.isEmpty
                ? const Center(
                    child: Text('No notifications'),
                  )
                : ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (context, index) {
                      final notification = _notifications[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4,),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                _getNotificationColor(notification.type),
                            child: Icon(
                              _getNotificationIcon(notification.type),
                              color: Colors.white,
                            ),
                          ),
                          title: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead
                                  ? FontWeight.normal
                                  : FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(notification.description),
                              const SizedBox(height: 4),
                              Text(
                                _formatDate(notification.date),
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          trailing: notification.isRead
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.mark_email_read),
                                  onPressed: () => _markAsRead(notification.id),
                                  tooltip: 'Mark as Read',
                                ),
                          isThreeLine: true,
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
        return Colors.orange;
      case NotificationType.deliverable:
        return Colors.blue;
      case NotificationType.sprint:
        return Colors.green;
      case NotificationType.repository:
        return Colors.purple;
      case NotificationType.system:
        return Colors.red;
      case NotificationType.team:
        return Colors.teal;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
        return Icons.approval;
      case NotificationType.deliverable:
        return Icons.assignment;
      case NotificationType.sprint:
        return Icons.timeline; // Changed from Icons.sprint to Icons.timeline
      case NotificationType.repository:
        return Icons.folder;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.team:
        return Icons.group;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Marked as read')),
    );
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('All notifications marked as read')),
    );
  }
}
