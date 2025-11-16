import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/realtime_service.dart';

class ConnectionStatusIndicator extends ConsumerStatefulWidget {
  final double size;
  final bool showTooltip;
  final Duration animationDuration;

  const ConnectionStatusIndicator({
    super.key,
    this.size = 16.0,
    this.showTooltip = true,
    this.animationDuration = const Duration(milliseconds: 300),
  });

  @override
  ConsumerState<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState
    extends ConsumerState<ConnectionStatusIndicator> {
  bool _isConnected = false;
  bool _isConnecting = false;
  String _statusMessage = 'Connecting...';

  @override
  void initState() {
    super.initState();
    _setupConnectionListener();
  }

  void _setupConnectionListener() {
    realtimeService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
          _isConnecting = false;
          _statusMessage = connected ? 'Connected' : 'Disconnected';
        });
      }
    });

    // Check initial connection state
    if (realtimeService.isConnected) {
      setState(() {
        _isConnected = true;
        _statusMessage = 'Connected';
      });
    } else {
      setState(() {
        _isConnecting = true;
        _statusMessage = 'Connecting...';
      });

      // Try to initialize connection
      realtimeService.initialize().then((_) {
        if (mounted) {
          setState(() {
            _isConnecting = false;
            _isConnected = realtimeService.isConnected;
            _statusMessage = realtimeService.isConnected ? 'Connected' : 'Disconnected';
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    IconData statusIcon;

    if (_isConnected) {
      statusColor = Colors.green;
      statusIcon = Icons.circle;
    } else if (_isConnecting) {
      statusColor = Colors.orange;
      statusIcon = Icons.circle;
    } else {
      statusColor = Colors.red;
      statusIcon = Icons.circle;
    }

    final indicator = Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: statusColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            // ignore: deprecated_member_use
            color: statusColor.withOpacity(0.5),
            blurRadius: 4.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Icon(
        statusIcon,
        size: widget.size * 0.6,
        color: Colors.white,
      ),
    );

    if (!widget.showTooltip) {
      return indicator;
    }

    return Tooltip(
      message: _statusMessage,
      child: indicator,
    );
  }
}

class ConnectionStatusWithText extends ConsumerWidget {
  final TextStyle? textStyle;
  final double spacing;

  const ConnectionStatusWithText({
    super.key,
    this.textStyle,
    this.spacing = 8.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectionState = ref.watch(_connectionStatusProvider);

    return connectionState.when(
      loading: () => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ConnectionStatusIndicator(size: 12, showTooltip: false),
          SizedBox(width: spacing),
          Text(
            'Connecting...',
            style: textStyle ?? Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      error: (error, stack) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ConnectionStatusIndicator(size: 12, showTooltip: false),
          SizedBox(width: spacing),
          Text(
            'Error',
            style: textStyle ?? Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      data: (connectionState) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ConnectionStatusIndicator(size: 12, showTooltip: false),
          SizedBox(width: spacing),
          Text(
            connectionState.message,
            style: textStyle ?? Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

final _connectionStatusProvider = StreamProvider<ConnectionState>((ref) {
  final controller = StreamController<ConnectionState>();

  void updateState(bool isConnected) {
    controller.add(ConnectionState(
      isConnected: isConnected,
      message: isConnected ? 'Connected' : 'Disconnected',
    ),);
  }

  // Listen to connection changes
  realtimeService.connectionStream.listen(updateState);

  // Initial state
  updateState(realtimeService.isConnected);

  return controller.stream;
});

class ConnectionState {
  final bool isConnected;
  final String message;

  ConnectionState({required this.isConnected, required this.message});
}