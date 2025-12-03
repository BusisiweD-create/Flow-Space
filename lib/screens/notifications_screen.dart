import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';
import '../providers/notification_provider.dart';
import 'report_repository_screen.dart';
import 'client_review_workflow_screen.dart';
import 'approval_requests_screen.dart';
import 'repository_screen.dart';
import 'enhanced_notifications_screen.dart';

class NotificationsScreen extends StatelessWidget {
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

  void _markAllAsRead() async {
    await ref.read(notificationProvider.notifier).markAllAsRead();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: FlownetColors.emeraldGreen,
      ),
    );
  }

  void _markAsRead(String notificationId) async {
    await ref.read(notificationProvider.notifier).markAsRead(notificationId);
  }

  void _openNotification(NotificationItem notification) async {
    await ref.read(notificationProvider.notifier).markAsRead(notification.id);
    if (!mounted) return;

    switch (notification.type) {
      case NotificationType.reportSubmission:
      case NotificationType.reportApproved:
      case NotificationType.reportChangesRequested:
        if (notification.relatedId != null && notification.relatedId!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ClientReviewWorkflowScreen(reportId: notification.relatedId!),
            ),
          );
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportRepositoryScreen()),
          );
        }
        break;
      case NotificationType.approval:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ApprovalRequestsScreen()),
        );
        break;
      case NotificationType.repository:
      case NotificationType.file:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const RepositoryScreen()),
        );
        break;
      case NotificationType.deliverable:
      case NotificationType.sprint:
      case NotificationType.system:
      case NotificationType.team:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ReportRepositoryScreen()),
        );
        break;
    }
  }

  // Helper method to convert API notification type string to NotificationType enum

  // Helper method to generate title from notification type

  @override
  Widget build(BuildContext context) {
    return const EnhancedNotificationsScreen();
  }
}