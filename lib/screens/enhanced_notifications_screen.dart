import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class EnhancedNotificationsScreen extends ConsumerStatefulWidget {
  const EnhancedNotificationsScreen({super.key});

  @override
  ConsumerState<EnhancedNotificationsScreen> createState() => _EnhancedNotificationsScreenState();
}

class _EnhancedNotificationsScreenState extends ConsumerState<EnhancedNotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  List<NotificationItem> _notifications = [];
  bool _isLoading = true;

  int get _unreadCount => _notifications.where((n) => !n.isRead).length;
  int get _totalCount => _notifications.length;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Set auth token
      final token = await _authService.getToken();
      if (token != null) {
        _notificationService.setAuthToken(token);
      }

      final notifications = await _notificationService.getNotifications();
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const FlownetLogo(),
                const Spacer(),
                Text(
                  'Notifications',
                  style: TextStyle(
                    color: FlownetColors.electricBlue,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                    decorationColor: FlownetColors.electricBlue,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.mark_email_read,
                    color: FlownetColors.electricBlue,
                  ),
                  onPressed: _markAllAsRead,
                  tooltip: 'Mark all as read',
                ),
              ],
            ),
          ),

          // Summary Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FlownetColors.amberOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_unreadCount',
                          style: const TextStyle(
                            color: FlownetColors.pureWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Unread',
                          style: TextStyle(
                            color: FlownetColors.pureWhite,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FlownetColors.electricBlue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$_totalCount',
                          style: const TextStyle(
                            color: FlownetColors.pureWhite,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          'Total',
                          style: TextStyle(
                            color: FlownetColors.pureWhite,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notifications list
          Expanded(
            child: ListView.builder(
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final notification = _notifications[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  color: notification.isRead
                      ? FlownetColors.graphiteGray
                      : FlownetColors.slate,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getNotificationTypeColor(notification.type),
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                                color: FlownetColors.electricBlue),
                            onPressed: () => _markAsRead(notification.id),
                            tooltip: 'Mark as read',
                          ),
                    isThreeLine: true,
                    onTap: () => _showNotificationDetail(notification),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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

  void _showNotificationDetail(NotificationItem notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: _getNotificationTypeColor(notification.type),
              child: Icon(
                _getNotificationTypeIcon(notification.type),
                color: FlownetColors.pureWhite,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                notification.title,
                style: const TextStyle(
                  color: FlownetColors.pureWhite,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.message,
              style: const TextStyle(
                color: FlownetColors.pureWhite,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlownetColors.slate,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Details',
                    style: TextStyle(
                      color: FlownetColors.electricBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Type: ${notification.type.name.toUpperCase()}',
                    style: const TextStyle(
                      color: FlownetColors.coolGray,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Time: ${_formatTimestamp(notification.timestamp)}',
                    style: const TextStyle(
                      color: FlownetColors.coolGray,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Status: ${notification.isRead ? "Read" : "Unread"}',
                    style: TextStyle(
                      color: notification.isRead ? Colors.green : FlownetColors.electricBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!notification.isRead)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markAsRead(notification.id);
              },
              child: const Text(
                'Mark as Read',
                style: TextStyle(color: FlownetColors.electricBlue),
              ),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Close',
              style: TextStyle(color: FlownetColors.pureWhite),
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
        return Colors.green;
      case NotificationType.repository:
        return Colors.purple;
      case NotificationType.deliverable:
        return FlownetColors.electricBlue;
      case NotificationType.system:
        return Colors.grey;
      case NotificationType.team:
        return Colors.blue;
      case NotificationType.file:
        return Colors.orange;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
        return Icons.person;
      case NotificationType.sprint:
        return Icons.trending_up;
      case NotificationType.repository:
        return Icons.folder;
      case NotificationType.deliverable:
        return Icons.description;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.team:
        return Icons.group;
      case NotificationType.file:
        return Icons.attach_file;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
