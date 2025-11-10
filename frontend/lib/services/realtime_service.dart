// ignore_for_file: avoid_print

import 'package:socket_io_client/socket_io_client.dart' as io;
import '../services/api_service.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';
import '../models/notification.dart';
import 'dart:async';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  io.Socket? _socket;
  bool _isConnected = false;
  final Map<String, List<Function>> _eventListeners = {};
  final Map<String, List<Function>> _onceListeners = {};

  // Connection state stream
  final StreamController<bool> _connectionController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _connectionController.stream;

  // Reconnect timer
  Timer? _reconnectTimer;
  bool _shouldReconnect = true;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 10;
  static const Duration _reconnectDelay = Duration(seconds: 5);

  /// Initialize the real-time service connection
  Future<void> initialize() async {
    if (_socket != null && _isConnected) {
      return;
    }

    final token = ApiService.accessToken;
    if (token == null) {
      return;
    }

    try {
      // Disconnect existing socket if any
      _socket?.disconnect();
      _socket?.dispose();

      // Create new socket connection with proper authentication
      _socket = io.io(
        'http://127.0.0.1:8000',
        io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .setAuth({'token': token})
          .build(),
      );

      _setupSocketEvents();
      _socket!.connect();

    } catch (e) {
      print('Failed to initialize real-time service: \$e');
      _scheduleReconnect();
    }
  }

  /// Set up socket event handlers
  void _setupSocketEvents() {
    _socket!
      ..onConnect((_) {
        print('✅ Connected to real-time server');
        _isConnected = true;
        _reconnectAttempts = 0;
        _connectionController.add(true);
        _authenticate();
      })
      ..onDisconnect((_) {
        print('❌ Disconnected from real-time server');
        _isConnected = false;
        _connectionController.add(false);
        _scheduleReconnect();
      })
      ..onError((data) {
        print('⚠️ Socket error: \$data');
        _isConnected = false;
        _connectionController.add(false);
      })
      ..on('connect_error', (data) {
        print('⚠️ Connection error: \$data');
        _isConnected = false;
        _connectionController.add(false);
      })
      ..on('connected', (data) {
        print('✅ Socket connection confirmed: \$data');
        _joinUserRooms();
      });

    // Setup real-time data event handlers
    _setupDataEventHandlers();
  }

  /// Authenticate the socket connection
  /// Note: Authentication is handled automatically during connection handshake
  /// via the auth object provided in the socket configuration
  void _authenticate() {
    // Authentication is handled automatically via the auth object
    // No need to emit a separate authenticate event
    print('✅ Socket authentication handled automatically during connection');
  }

  /// Join user-specific rooms
  void _joinUserRooms() {
    final user = ApiService.currentUserId;
    if (user != null) {
      // Join user's personal room
      _socket?.emit('join_user_room', {'userId': user});
      
      // Join role-based rooms
      // Note: We need to fetch the user role from user provider or API
      // For now, we'll skip role-based rooms until we have the user object
      _socket?.emit('join_role_room', {'role': 'teamMember'});
      
      // Join project rooms if user has projects
      // Note: Project rooms will be handled separately when we have project data
    }
  }

  /// Set up data event handlers for real-time updates
  void _setupDataEventHandlers() {
    // Deliverable events
    _socket!
      ..on('deliverable_created', (data) => _handleDeliverableCreated(data))
      ..on('deliverable_updated', (data) => _handleDeliverableUpdated(data))
      ..on('deliverable_deleted', (data) => _handleDeliverableDeleted(data))
      ..on('deliverable_status_changed', (data) => _handleDeliverableStatusChanged(data))
      
      // Sprint events
      ..on('sprint_created', (data) => _handleSprintCreated(data))
      ..on('sprint_updated', (data) => _handleSprintUpdated(data))
      ..on('sprint_deleted', (data) => _handleSprintDeleted(data))
      
      // Notification events
      ..on('notification_created', (data) => _handleNotificationCreated(data))
      ..on('notification_read', (data) => _handleNotificationRead(data))
      
      // User presence events
      ..on('user_online', (data) => _handleUserOnline(data))
      ..on('user_offline', (data) => _handleUserOffline(data))
      
      // Analytics events
      ..on('analytics_updated', (data) => _handleAnalyticsUpdated(data));
  }

  /// Handle deliverable created event
  void _handleDeliverableCreated(dynamic data) {
    try {
      final deliverable = Deliverable.fromJson(data);
      _emitEvent('deliverable_created', deliverable);
    } catch (e) {
      print('Error handling deliverable_created event: \$e');
    }
  }

  /// Handle deliverable updated event
  void _handleDeliverableUpdated(dynamic data) {
    try {
      final deliverable = Deliverable.fromJson(data);
      _emitEvent('deliverable_updated', deliverable);
    } catch (e) {
      print('Error handling deliverable_updated event: \$e');
    }
  }

  /// Handle deliverable deleted event
  void _handleDeliverableDeleted(dynamic data) {
    try {
      final deliverableId = data['id'] as String;
      _emitEvent('deliverable_deleted', deliverableId);
    } catch (e) {
      print('Error handling deliverable_deleted event: \$e');
    }
  }

  /// Handle deliverable status changed event
  void _handleDeliverableStatusChanged(dynamic data) {
    try {
      final eventData = {
        'deliverableId': data['deliverableId'],
        'oldStatus': data['oldStatus'],
        'newStatus': data['newStatus'],
        'updatedBy': data['updatedBy'],
      };
      _emitEvent('deliverable_status_changed', eventData);
    } catch (e) {
      print('Error handling deliverable_status_changed event: \$e');
    }
  }

  /// Handle sprint created event
  void _handleSprintCreated(dynamic data) {
    try {
      final sprint = Sprint.fromJson(data);
      _emitEvent('sprint_created', sprint);
    } catch (e) {
      print('Error handling sprint_created event: \$e');
    }
  }

  /// Handle sprint updated event
  void _handleSprintUpdated(dynamic data) {
    try {
      final sprint = Sprint.fromJson(data);
      _emitEvent('sprint_updated', sprint);
    } catch (e) {
      print('Error handling sprint_updated event: \$e');
    }
  }

  /// Handle sprint deleted event
  void _handleSprintDeleted(dynamic data) {
    try {
      final sprintId = data['id'] as String;
      _emitEvent('sprint_deleted', sprintId);
    } catch (e) {
      print('Error handling sprint_deleted event: \$e');
    }
  }

  /// Handle notification created event
  void _handleNotificationCreated(dynamic data) {
    try {
      final notification = Notification.fromJson(data);
      _emitEvent('notification_created', notification);
    } catch (e) {
      print('Error handling notification_created event: \$e');
    }
  }

  /// Handle notification read event
  void _handleNotificationRead(dynamic data) {
    try {
      final notificationId = data['id'] as String;
      _emitEvent('notification_read', notificationId);
    } catch (e) {
      print('Error handling notification_read event: \$e');
    }
  }

  /// Handle user online event
  void _handleUserOnline(dynamic data) {
    try {
      final userId = data['userId'] as String;
      _emitEvent('user_online', userId);
    } catch (e) {
      print('Error handling user_online event: \$e');
    }
  }

  /// Handle user offline event
  void _handleUserOffline(dynamic data) {
    try {
      final userId = data['userId'] as String;
      _emitEvent('user_offline', userId);
    } catch (e) {
      print('Error handling user_offline event: \$e');
    }
  }

  /// Handle analytics updated event
  void _handleAnalyticsUpdated(dynamic data) {
    try {
      // Analytics data comes as a Map, not a specific AnalyticsData model
      _emitEvent('analytics_updated', data);
    } catch (e) {
      print('Error handling analytics_updated event: \$e');
    }
  }

  /// Emit event to all registered listeners
  void _emitEvent(String eventName, dynamic data) {
    final listeners = _eventListeners[eventName];
    if (listeners != null) {
      for (final listener in listeners) {
        try {
          listener(data);
        } catch (e) {
          print('Error in event listener for \$eventName: \$e');
        }
      }
    }

    final onceListeners = _onceListeners[eventName];
    if (onceListeners != null && onceListeners.isNotEmpty) {
      for (final listener in onceListeners) {
        try {
          listener(data);
        } catch (e) {
          print('Error in once listener for \$eventName: \$e');
        }
      }
      _onceListeners[eventName]?.clear();
    }
  }

  /// Schedule reconnection attempt
  void _scheduleReconnect() {
    if (!_shouldReconnect || _reconnectAttempts >= _maxReconnectAttempts) {
      return;
    }

    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(_reconnectDelay * (_reconnectAttempts + 1), () {
      _reconnectAttempts++;
      print('Attempting to reconnect (attempt \$_reconnectAttempts/\$_maxReconnectAttempts)...');
      initialize();
    });
  }

  /// Add event listener
  void on(String eventName, Function(dynamic) listener) {
    if (!_eventListeners.containsKey(eventName)) {
      _eventListeners[eventName] = [];
    }
    _eventListeners[eventName]!.add(listener);
  }

  /// Add one-time event listener
  void once(String eventName, Function(dynamic) listener) {
    if (!_onceListeners.containsKey(eventName)) {
      _onceListeners[eventName] = [];
    }
    _onceListeners[eventName]!.add(listener);
  }

  /// Remove event listener
  void off(String eventName, Function(dynamic) listener) {
    _eventListeners[eventName]?.remove(listener);
    _onceListeners[eventName]?.remove(listener);
  }

  /// Remove all listeners for an event
  void offAll(String eventName) {
    _eventListeners.remove(eventName);
    _onceListeners.remove(eventName);
  }

  /// Emit custom event to server
  void emit(String eventName, dynamic data) {
    if (_isConnected) {
      _socket?.emit(eventName, data);
    }
  }

  /// Check if connected to real-time server
  bool get isConnected => _isConnected;

  /// Disconnect from real-time server
  void disconnect() {
    _shouldReconnect = false;
    _reconnectTimer?.cancel();
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    _connectionController.add(false);
  }

  /// Clean up resources
  void dispose() {
    disconnect();
    _connectionController.close();
    _eventListeners.clear();
    _onceListeners.clear();
  }
}

// Global instance
final realtimeService = RealtimeService();