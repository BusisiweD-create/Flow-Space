import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
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
      message: 'John Doe has requested approval for User Authentication System.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    NotificationItem(
      id: '2',
      title: 'Sprint Completed',
      description: 'Sprint 3 has been completed successfully',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      isRead: false,
      type: NotificationType.sprint,
      message: 'Sprint 3 has been completed successfully.',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    NotificationItem(
      id: '3',
      title: 'File Uploaded',
      description: 'Alice Johnson uploaded project_design.pdf to repository',
      date: DateTime.now().subtract(const Duration(hours: 4)),
      isRead: true,
      type: NotificationType.repository,
      message: 'Alice Johnson uploaded project_design.pdf to repository.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
    ),
    NotificationItem(
      id: '4',
      title: 'Deliverable Due',
      description: 'Database Schema Update deliverable is due tomorrow',
      date: DateTime.now().subtract(const Duration(days: 1)),
      isRead: true,
      type: NotificationType.deliverable,
      message: 'Database Schema Update deliverable is due tomorrow.',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final totalCount = _notifications.length;

    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      appBar: AppBar(
        title: const FlownetLogo(showText: true),
        backgroundColor: FlownetColors.charcoalBlack,
        foregroundColor: FlownetColors.pureWhite,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Column(
        children: [
          // Summary cards
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Card(
                    color: FlownetColors.amberOrange,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '$unreadCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: FlownetColors.pureWhite,
                            ),
                          ),
                          const Text(
                            'Unread',
                            style: TextStyle(
                              color: FlownetColors.pureWhite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    color: FlownetColors.electricBlue,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            '$totalCount',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: FlownetColors.pureWhite,
                            ),
                          ),
                          const Text(
                            'Total',
                            style: TextStyle(
                              color: FlownetColors.pureWhite,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Notifications list
          Expanded(
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: notification.isRead
                      ? FlownetColors.graphiteGray
                      : FlownetColors.slate,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationTypeColor(
                          notification.type,),
                      child: Icon(
                        _getNotificationTypeIcon(notification.type),
                        color: FlownetColors.pureWhite,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      notification.title,
                      style: TextStyle(
                        fontWeight: notification.isRead
                            ? FontWeight.normal
                            : FontWeight.bold,
                        color: FlownetColors.pureWhite,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.message,
                          style: const TextStyle(
                            color: FlownetColors.coolGray,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTimestamp(notification.timestamp),
                          style: const TextStyle(
                            color: FlownetColors.coolGray,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    trailing: notification.isRead
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.mark_email_read,
                                color: FlownetColors.electricBlue,),
                            onPressed: () => _markAsRead(notification.id),
                            tooltip: 'Mark as read',
                          ),
                    isThreeLine: true,
                    onTap: () => _markAsRead(notification.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
        return FlownetColors.amberOrange;
      case NotificationType.sprint:
        return FlownetColors.emeraldGreen;
      case NotificationType.file:
        return FlownetColors.crimsonRed;
      case NotificationType.deliverable:
        return FlownetColors.electricBlue;
      case NotificationType.repository:
        return FlownetColors.purple;
      case NotificationType.system:
        return FlownetColors.red;
      case NotificationType.team:
        return FlownetColors.teal;
      case NotificationType.reportSubmission:
        return FlownetColors.electricBlue;
      case NotificationType.reportApproved:
        return FlownetColors.emeraldGreen;
      case NotificationType.reportChangesRequested:
        return FlownetColors.amberOrange;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
        return Icons.approval;
      case NotificationType.sprint:
        return Icons.trending_up;
      case NotificationType.file:
        return Icons.upload_file;
      case NotificationType.deliverable:
        return Icons.assignment;
      case NotificationType.repository:
        return Icons.folder;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.team:
        return Icons.group;
      case NotificationType.reportSubmission:
        return Icons.assignment_turned_in;
      case NotificationType.reportApproved:
        return Icons.check_circle;
      case NotificationType.reportChangesRequested:
        return Icons.edit_note;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _markAsRead(String id) {
    setState(() {
      final index = _notifications.indexWhere((n) => n.id == id);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (int i = 0; i < _notifications.length; i++) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
  }
}