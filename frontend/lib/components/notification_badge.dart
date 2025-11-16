import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';

class NotificationBadge extends ConsumerWidget {
  final double size;
  final Color? badgeColor;
  final Color? textColor;
  final VoidCallback? onTap;

  const NotificationBadge({
    super.key,
    this.size = 24.0,
    this.badgeColor,
    this.textColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: badgeColor ?? Theme.of(context).colorScheme.error,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            unreadCount > 99 ? '99+' : unreadCount.toString(),
            style: TextStyle(
              color: textColor ?? Theme.of(context).colorScheme.onError,
              fontSize: size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedNotificationBadge extends ConsumerStatefulWidget {
  final double size;
  final Color? badgeColor;
  final Color? textColor;
  final VoidCallback? onTap;
  final Duration animationDuration;

  const AnimatedNotificationBadge({
    super.key,
    this.size = 24.0,
    this.badgeColor,
    this.textColor,
    this.onTap,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  ConsumerState<AnimatedNotificationBadge> createState() =>
      _AnimatedNotificationBadgeState();
}

class _AnimatedNotificationBadgeState
    extends ConsumerState<AnimatedNotificationBadge> {
  int _previousCount = 0;
  bool _isAnimating = false;

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    final unreadCount = notificationState.unreadCount;

    if (unreadCount != _previousCount && unreadCount > _previousCount) {
      _isAnimating = true;
      Future.delayed(widget.animationDuration, () {
        if (mounted) {
          setState(() {
            _isAnimating = false;
          });
        }
      });
    }
    _previousCount = unreadCount;

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: widget.animationDuration,
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.badgeColor ?? Theme.of(context).colorScheme.error,
          shape: BoxShape.circle,
          boxShadow: _isAnimating
              ? [
                  BoxShadow(
                    // ignore: deprecated_member_use
                    color: Theme.of(context).colorScheme.error.withOpacity(0.5),
                    blurRadius: 8.0,
                    spreadRadius: 2.0,
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            unreadCount > 99 ? '99+' : unreadCount.toString(),
            style: TextStyle(
              color: widget.textColor ?? Theme.of(context).colorScheme.onError,
              fontSize: widget.size * 0.5,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}