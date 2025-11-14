import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../providers/notification_provider.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  void _markAllAsRead() {
    // This would need to be implemented in the notification provider
    // For now, we'll just reload notifications
    ref.read(notificationProvider.notifier).loadNotifications();
  }

  void _markAsRead(String notificationId) {
    // This would need to be implemented in the notification provider
    // For now, we'll just reload notifications
    ref.read(notificationProvider.notifier).loadNotifications();
  }

  // Helper method to convert API notification type string to NotificationType enum

  // Helper method to generate title from notification type

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    
    if (notificationState.isLoading) {
      return const Scaffold(
        backgroundColor: FlownetColors.charcoalBlack,
        body: Center(
          child: CircularProgressIndicator(
            color: FlownetColors.electricBlue,
          ),
        ),
      );
    }
    
    if (notificationState.error != null) {
      return Scaffold(
        backgroundColor: FlownetColors.charcoalBlack,
        appBar: AppBar(
          title: const FlownetLogo(showText: true),
          backgroundColor: FlownetColors.charcoalBlack,
          foregroundColor: FlownetColors.pureWhite,
          centerTitle: false,
        ),
        body: Center(
          child: Text(
            'Error loading notifications: ${notificationState.error}',
            style: const TextStyle(color: FlownetColors.pureWhite),
          ),
        ),
      );
    }
    
    final notifications = notificationState.notifications;
    final unreadCount = notificationState.unreadCount;
    final totalCount = notifications.length;

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
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                final notification = notifications[index];
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


}