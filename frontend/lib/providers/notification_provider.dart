// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../models/notification.dart' as model;

class NotificationState {
  final List<model.Notification> notifications;
  final bool isLoading;
  final String? error;
  final int unreadCount;

  NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
    this.unreadCount = 0,
  });

  NotificationState copyWith({
    List<model.Notification>? notifications,
    bool? isLoading,
    String? error,
    int? unreadCount,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier(this.ref) : super(NotificationState()) {
    _initialize();
  }

  final Ref ref;
  Timer? _pollingTimer;
  bool _useRealtime = true;

  Future<void> _initialize() async {
    await _loadNotifications();
    _setupRealtimeListeners();
    _startPolling();
  }

  Future<void> _loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Only use real API data
      if (!ApiService.isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication required. Please log in to view notifications.',
        );
        return;
      }
      
      final notifications = await ApiService.getNotifications();
      final unreadCount = notifications.where((n) => !n.isRead).length;
      state = state.copyWith(
        notifications: notifications,
        isLoading: false,
        unreadCount: unreadCount,
      );
    } catch (e) {
      // Handle specific permission errors
      String errorMessage = 'Failed to load notifications. Please check your connection and try again.';
      if (e.toString().contains('403') || e.toString().contains('permission') || e.toString().contains('Forbidden')) {
        errorMessage = 'Permission denied. Please check your user permissions or contact your administrator.';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
    }
  }

  void _setupRealtimeListeners() {
    if (!_useRealtime) return;

    try {
      // Set up real-time notification listeners
      realtimeService.on('notification_created', _handleNotificationCreated);
      realtimeService.on('notification_read', _handleNotificationRead);
      
      // Listen for connection state changes
      realtimeService.connectionStream.listen((isConnected) {
        if (!isConnected && _useRealtime) {
          print('Real-time connection lost, falling back to polling');
          _useRealtime = false;
          _startPolling();
        } else if (isConnected && !_useRealtime) {
          print('Real-time connection restored');
          _useRealtime = true;
          _pollingTimer?.cancel();
          _pollingTimer = null;
        }
      });
      
      // Initialize real-time service if not already connected
      if (!realtimeService.isConnected) {
        realtimeService.initialize();
      }
      
    } catch (e) {
      print('Failed to set up real-time listeners: \$e');
      _useRealtime = false;
      _startPolling();
    }
  }
  
  void _handleNotificationCreated(dynamic data) {
    try {
      final notification = model.Notification.fromJson(data);
      _addNotification(notification);
    } catch (e) {
      print('Error handling real-time notification: \$e');
    }
  }
  
  void _handleNotificationRead(dynamic data) {
    try {
      final notificationId = data['id'] as String;
      final updatedNotifications = state.notifications.map((n) {
        // ignore: unrelated_type_equality_checks
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Error handling notification read update: \$e');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadNotifications();
    });
  }

  void _addNotification(model.Notification notification) {
    final currentNotifications = List<model.Notification>.from(state.notifications);
    
    // Remove existing notification with same ID if any
    currentNotifications.removeWhere((n) => n.id == notification.id);
    
    // Add new notification at the beginning
    currentNotifications.insert(0, notification);
    
    final unreadCount = currentNotifications.where((n) => !n.isRead).length;
    
    state = state.copyWith(
      notifications: currentNotifications,
      unreadCount: unreadCount,
    );

    // Show local notification if enabled
    if (notification.type == 'sprint_created' || 
        notification.type == 'deliverable_created') {
      _showLocalNotification(notification);
    }
  }

  Future<void> _showLocalNotification(model.Notification notification) async {
    // This would integrate with the local notification service
    // For now, we'll just print to console
    print('New notification: \${notification.title} - \${notification.message}');
  }

  Future<void> markAsRead(int notificationId) async {
    try {
      await ApiService.markNotificationAsRead(notificationId);
      
      final updatedNotifications = state.notifications.map((n) {
        if (n.id == notificationId) {
          return n.copyWith(isRead: true);
        }
        return n;
      }).toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Failed to mark notification as read: \$e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await ApiService.markAllNotificationsAsRead();
      
      final updatedNotifications = state.notifications
          .map((n) => n.copyWith(isRead: true))
          .toList();

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: 0,
      );
    } catch (e) {
      print('Failed to mark all notifications as read: \$e');
    }
  }

  Future<void> deleteNotification(String notificationId) async {
    try {
      await ApiService.deleteNotification(notificationId);
      
      final updatedNotifications = state.notifications
          // ignore: unrelated_type_equality_checks
          .where((n) => n.id != notificationId)
          .toList();

      final unreadCount = updatedNotifications.where((n) => !n.isRead).length;

      state = state.copyWith(
        notifications: updatedNotifications,
        unreadCount: unreadCount,
      );
    } catch (e) {
      print('Failed to delete notification: \$e');
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    
    // Clean up real-time listeners
    realtimeService.off('notification_created', _handleNotificationCreated);
    realtimeService.off('notification_read', _handleNotificationRead);
    
    super.dispose();
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});