import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/app_scaffold.dart';

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

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final token = _authService.accessToken;
      if (token != null) {
        _notificationService.setAuthToken(token);
      }

      final notifications = await _notificationService.getNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const AppScaffold(
        useBackgroundImage: true,
        centered: false,
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
      );
    }

    return AppScaffold(
      useBackgroundImage: true,
      centered: false,
      scrollable: false,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.mark_email_read, color: Colors.white),
            onPressed: _markAllAsRead,
            tooltip: 'Mark all as read',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCards(),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                return _buildNotificationCard(_notifications[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(NotificationItem notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: (notification.isRead
              ? FlownetColors.graphiteGray
              : FlownetColors.slate)
          .withAlpha((0.65 * 255).toInt()),

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
            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
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
                icon: const Icon(Icons.mark_email_read, color: FlownetColors.electricBlue),
                onPressed: () => _markAsRead(notification.id),
                tooltip: 'Mark as read',
              ),
        isThreeLine: true,
        onTap: () => _showNotificationDetail(notification),
      ),
    );
  }

  Widget _buildSummaryCards() {
    final unreadCount = _notifications.where((n) => !n.isRead).length;
    final totalCount = _notifications.length;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          _buildSummaryCard(
            value: unreadCount,
            label: 'Unread',
            color: FlownetColors.electricBlue,
          ),
          const SizedBox(width: 16),
          _buildSummaryCard(
            value: totalCount,
            label: 'Total',
            color: FlownetColors.slate,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required int value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withAlpha((0.55 * 255).toInt()),

          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                color: FlownetColors.pureWhite,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: FlownetColors.pureWhite,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getNotificationTypeColor(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
      case NotificationType.reportApproved:
        return Colors.green;
      case NotificationType.reportChangesRequested:
      case NotificationType.sprint:
        return Colors.orange;
      case NotificationType.system:
      case NotificationType.reportSubmission:
        return FlownetColors.electricBlue;
      case NotificationType.deliverable:
      case NotificationType.repository:
      case NotificationType.team:
      case NotificationType.file:
        return FlownetColors.charcoalBlack;
    }
  }

  IconData _getNotificationTypeIcon(NotificationType type) {
    switch (type) {
      case NotificationType.approval:
      case NotificationType.reportApproved:
        return Icons.check_circle;
      case NotificationType.reportChangesRequested:
        return Icons.edit_note;
      case NotificationType.sprint:
        return Icons.directions_run;
      case NotificationType.system:
        return Icons.settings;
      case NotificationType.reportSubmission:
        return Icons.assignment_turned_in;
      case NotificationType.deliverable:
        return Icons.assignment;
      case NotificationType.repository:
        return Icons.code;
      case NotificationType.team:
        return Icons.people;
      case NotificationType.file:
        return Icons.insert_drive_file;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return '$minutes ${minutes == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
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
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All notifications marked as read'),
          backgroundColor: FlownetColors.electricBlue,
        ),
      );
    }
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
                  const Text(
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
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          if (!notification.isRead)
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _markAsRead(notification.id);
              },
              child: const Text('Mark as Read'),
            ),
        ],
      ),
    );
  }
}