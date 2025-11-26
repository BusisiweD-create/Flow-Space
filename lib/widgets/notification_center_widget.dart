import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/notification_service.dart';
import '../services/realtime_service.dart';
import '../services/auth_service.dart';
import '../theme/flownet_theme.dart';

class NotificationCenterWidget extends StatefulWidget {
  const NotificationCenterWidget({super.key});

  @override
  State<NotificationCenterWidget> createState() => _NotificationCenterWidgetState();
}

class _NotificationCenterWidgetState extends State<NotificationCenterWidget> {
  final NotificationService _notificationService = NotificationService();
  final AuthService _authService = AuthService();
  late RealtimeService _realtime;
  
  int _unreadCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _realtime = RealtimeService();
    _realtime.initialize(authToken: _authService.accessToken);
    _realtime.on('notification_received', (_) => _loadUnreadCount());
    _loadUnreadCount();
  }

  Future<void> _loadUnreadCount() async {
    try {
      final token = _authService.accessToken;
      if (token != null) {
        _notificationService.setAuthToken(token);
        final count = await _notificationService.getUnreadCount();
        if (mounted) {
          setState(() {
            _unreadCount = count;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading notification count: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _realtime.offAll('notification_received');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.go('/notifications');
        // Refresh count after navigation
        _loadUnreadCount();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: FlownetColors.graphiteGray,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: FlownetColors.pureWhite,
                  size: 20,
                ),
                if (_unreadCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: FlownetColors.crimsonRed,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                        style: const TextStyle(
                          color: FlownetColors.pureWhite,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            if (_isLoading)
              const SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(FlownetColors.pureWhite),
                ),
              )
            else
              const Text(
                'Notifications',
                style: TextStyle(
                  color: FlownetColors.pureWhite,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
