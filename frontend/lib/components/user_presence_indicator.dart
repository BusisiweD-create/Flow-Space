import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';

class UserPresenceIndicator extends ConsumerStatefulWidget {
  final String userId;
  final double size;
  final bool showTooltip;
  final Color onlineColor;
  final Color offlineColor;
  final Color awayColor;

  const UserPresenceIndicator({
    super.key,
    required this.userId,
    this.size = 12.0,
    this.showTooltip = true,
    this.onlineColor = Colors.green,
    this.offlineColor = Colors.grey,
    this.awayColor = Colors.orange,
  });

  @override
  ConsumerState<UserPresenceIndicator> createState() =>
      _UserPresenceIndicatorState();
}

class _UserPresenceIndicatorState extends ConsumerState<UserPresenceIndicator> {
  bool _isOnline = false;
  bool _isAway = false;

  @override
  void initState() {
    super.initState();
    _setupPresenceListeners();
    _requestUserStatus();
  }

  void _setupPresenceListeners() {
    // Listen for user online/offline events
    realtimeService.on('user_online', _handleUserOnline);
    realtimeService.on('user_offline', _handleUserOffline);
    realtimeService.on('user_activity', _handleUserActivity);
  }

  void _requestUserStatus() {
    // Emit event to request current user status
    realtimeService.emit('get_user_status', {'userId': widget.userId});
  }

  @override
  void didUpdateWidget(covariant UserPresenceIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _requestUserStatus();
    }
  }

  @override
  void dispose() {
    // Clean up listeners
    realtimeService.off('user_online', _handleUserOnline);
    realtimeService.off('user_offline', _handleUserOffline);
    realtimeService.off('user_activity', _handleUserActivity);
    super.dispose();
  }

  void _handleUserOnline(dynamic data) {
    if (data is String && data == widget.userId && mounted) {
      setState(() {
        _isOnline = true;
        _isAway = false;
      });
    }
  }

  void _handleUserOffline(dynamic data) {
    if (data is String && data == widget.userId && mounted) {
      setState(() {
        _isOnline = false;
        _isAway = false;
      });
    }
  }

  void _handleUserActivity(dynamic data) {
    if (data is Map && data['userId'] == widget.userId && mounted) {
      setState(() {
        _isOnline = true;
        _isAway = data['isAway'] ?? false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    String tooltipMessage;

    if (_isOnline && !_isAway) {
      statusColor = widget.onlineColor;
      tooltipMessage = 'Online';
    } else if (_isAway) {
      statusColor = widget.awayColor;
      tooltipMessage = 'Away';
    } else {
      statusColor = widget.offlineColor;
      tooltipMessage = 'Offline';
    }

    final indicator = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        border: Border.all(
          // ignore: deprecated_member_use
          color: Theme.of(context).colorScheme.background,
          width: 2.0,
        ),
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: statusColor.withOpacity(0.5),
            blurRadius: 3.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
    );

    if (!widget.showTooltip) {
      return indicator;
    }

    return Tooltip(
      message: tooltipMessage,
      child: indicator,
    );
  }
}

class UserPresenceWithAvatar extends StatelessWidget {
  final String userId;
  final String? avatarUrl;
  final String? displayName;
  final double avatarSize;
  final double indicatorSize;
  final Color onlineColor;
  final Color offlineColor;
  final Color awayColor;

  const UserPresenceWithAvatar({
    super.key,
    required this.userId,
    this.avatarUrl,
    this.displayName,
    this.avatarSize = 40.0,
    this.indicatorSize = 12.0,
    this.onlineColor = Colors.green,
    this.offlineColor = Colors.grey,
    this.awayColor = Colors.orange,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // User avatar
        CircleAvatar(
          radius: avatarSize / 2,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  displayName != null && displayName!.isNotEmpty
                      ? displayName![0].toUpperCase()
                      : '?',
                  style: TextStyle(fontSize: avatarSize * 0.4),
                )
              : null,
        ),
        // Presence indicator
        Positioned(
          bottom: 0,
          right: 0,
          child: UserPresenceIndicator(
            userId: userId,
            size: indicatorSize,
            onlineColor: onlineColor,
            offlineColor: offlineColor,
            awayColor: awayColor,
          ),
        ),
      ],
    );
  }
}

// Provider for user presence status
final userPresenceProvider = StreamProvider.family<Map<String, dynamic>, String>(
  (ref, userId) {
    final controller = StreamController<Map<String, dynamic>>();

    void updateStatus(bool isOnline, {bool isAway = false}) {
      controller.add({
        'isOnline': isOnline,
        'isAway': isAway,
        'status': isAway ? 'away' : (isOnline ? 'online' : 'offline'),
      });
    }

    // Listen for presence events
    realtimeService.on('user_online', (data) {
      if (data is String && data == userId) {
        updateStatus(true);
      }
    });

    realtimeService.on('user_offline', (data) {
      if (data is String && data == userId) {
        updateStatus(false);
      }
    });

    realtimeService.on('user_activity', (data) {
      if (data is Map && data['userId'] == userId) {
        updateStatus(true, isAway: data['isAway'] ?? false);
      }
    });

    // Request initial status
    realtimeService.emit('get_user_status', {'userId': userId});

    return controller.stream;
  },
);