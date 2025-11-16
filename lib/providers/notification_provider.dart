import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_item.dart';
import '../providers/service_providers.dart';

class NotificationState {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<NotificationItem>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends Notifier<NotificationState> {
  @override
  NotificationState build() {
    return const NotificationState();
  }

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final backend = ref.read(backendApiServiceProvider);
      final response = await backend.getNotifications(page: 1, limit: 50);

      if (!response.isSuccess || response.data == null) {
        state = state.copyWith(
          notifications: [],
          unreadCount: 0,
          isLoading: false,
        );
        return;
      }

      final raw = response.data!;
      final items = raw is List
          ? raw
          : (raw['data'] ?? raw['notifications'] ?? raw['items'] ?? []);

      final notifications = List<NotificationItem>.from(
        (items as List<dynamic>).map((item) {
          final t = (item['type']?.toString() ?? '').toLowerCase();
          final a = (item['action']?.toString() ?? '').toLowerCase();

          final type = NotificationType.values.firstWhere(
            (e) => e.name == t,
            orElse: () => NotificationType.system,
          );

          final action = NotificationAction.values.firstWhere(
            (e) => e.name == a,
            orElse: () => NotificationAction.general,
          );

          final createdAtStr = (item['createdAt']?.toString() ?? item['date']?.toString());
          final createdAt = createdAtStr != null && createdAtStr.isNotEmpty
              ? DateTime.parse(createdAtStr)
              : DateTime.now();

          final timestampStr = (item['timestamp']?.toString() ?? createdAtStr);
          final timestamp = timestampStr != null && timestampStr.isNotEmpty
              ? DateTime.parse(timestampStr)
              : createdAt;

          return NotificationItem(
            id: item['id']?.toString() ?? '',
            title: item['title']?.toString() ?? 'Notification',
            description: item['description']?.toString() ?? (item['message']?.toString() ?? ''),
            date: createdAt,
            isRead: item['isRead'] ?? false,
            type: type,
            message: item['message']?.toString() ?? '',
            timestamp: timestamp,
            action: action,
            relatedId: item['deliverableId']?.toString() ??
                item['reportId']?.toString() ??
                item['sprintId']?.toString() ??
                item['relatedId']?.toString(),
          );
        }),
      );

      final unreadCount = notifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: notifications,
        unreadCount: unreadCount,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load notifications: $e',
      );
    }
  }

  void markAsRead(String notificationId) {
    final updatedNotifications = state.notifications.map((notification) {
      if (notification.id == notificationId) {
        return notification.copyWith(isRead: true);
      }
      return notification;
    }).toList();

    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }

  void markAllAsRead() {
    final updatedNotifications = state.notifications
        .map((notification) => notification.copyWith(isRead: true))
        .toList();

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: 0,
    );
  }

  /// Add a new notification
  void addNotification(NotificationItem notification) {
    final updatedNotifications = [notification, ...state.notifications];
    final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

    state = state.copyWith(
      notifications: updatedNotifications,
      unreadCount: unreadCount,
    );
  }
}

final notificationProvider = NotifierProvider<NotificationNotifier, NotificationState>(
  () => NotificationNotifier(),
);