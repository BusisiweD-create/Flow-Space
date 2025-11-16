import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:flutter/foundation.dart';
import '../models/sprint_metrics.dart';
import 'auth_service.dart';

class QARealtimeService {
  final AuthService _authService;
  WebSocketChannel? _channel;
  final StreamController<SprintMetrics> _metricsController = StreamController<SprintMetrics>.broadcast();
  final StreamController<Map<String, dynamic>> _defectsController = StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<double> _testCoverageController = StreamController<double>.broadcast();
  
  bool _isConnected = false;
  Timer? _reconnectTimer;
  
  QARealtimeService(this._authService);
  
  Stream<SprintMetrics> get metricsStream => _metricsController.stream;
  Stream<Map<String, dynamic>> get defectsStream => _defectsController.stream;
  Stream<double> get testCoverageStream => _testCoverageController.stream;
  
  bool get isConnected => _isConnected;
  
  Future<void> connect() async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        throw Exception('No authentication token available');
      }
      
      const wsUrl = 'ws://localhost:8000/api/ws/qa-metrics?token=\$token';
      
      _channel = IOWebSocketChannel.connect(wsUrl);
      
      _channel!.stream.listen(
        (message) => _handleMessage(message),
        onError: (error) => _handleError(error),
        onDone: () => _handleDisconnect(),
      );
      
      _isConnected = true;
      
    } catch (e) {
      _scheduleReconnect();
    }
  }
  
  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
    _reconnectTimer?.cancel();
  }
  
  void _handleMessage(dynamic message) {
    try {
      final data = Map<String, dynamic>.from(message);
      final type = data['type'] as String?;
      
      switch (type) {
        case 'metrics_update':
          _handleMetricsUpdate(data['data']);
          break;
        case 'defects_update':
          _handleDefectsUpdate(data['data']);
          break;
        case 'test_coverage_update':
          _handleTestCoverageUpdate(data['data']);
          break;
        default:
          // Unknown message type - silently ignore
          break;
      }
    } catch (e) {
      // Error handling message - silently ignore
    }
  }
  
  void _handleMetricsUpdate(dynamic data) {
    try {
      final metrics = SprintMetrics.fromJson(Map<String, dynamic>.from(data));
      _metricsController.add(metrics);
    } catch (e) {
      // Error parsing metrics - silently ignore
    }
  }
  
  void _handleDefectsUpdate(dynamic data) {
    try {
      final defects = Map<String, dynamic>.from(data);
      _defectsController.add(defects);
    } catch (e) {
      // Error parsing defects - silently ignore
    }
  }
  
  void _handleTestCoverageUpdate(dynamic data) {
    try {
      final coverage = (data as num).toDouble();
      _testCoverageController.add(coverage);
    } catch (e) {
      // Error parsing test coverage - silently ignore
    }
  }
  
  void _handleError(dynamic error) {
    _handleDisconnect();
  }
  
  void _handleDisconnect() {
    _isConnected = false;
    _scheduleReconnect();
  }
  
  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        connect();
      }
    });
  }
  
  Future<void> sendCommand(String command, Map<String, dynamic> data) async {
    if (_channel == null || !_isConnected) {
      throw Exception('WebSocket not connected');
    }
    
    final message = {
      'type': 'command',
      'command': command,
      'data': data,
    };
    
    _channel!.sink.add(message);
  }
  
  void dispose() {
    disconnect();
    _metricsController.close();
    _defectsController.close();
    _testCoverageController.close();
    _reconnectTimer?.cancel();
  }
}

// Provider for QA realtime service
class QARealtimeProvider with ChangeNotifier {
  final QARealtimeService _service;
  SprintMetrics? _currentMetrics;
  Map<String, dynamic>? _currentDefects;
  double? _currentTestCoverage;
  bool _isLoading = true;
  String? _error;
  
  QARealtimeProvider(this._service) {
    _initialize();
  }
  
  SprintMetrics? get metrics => _currentMetrics;
  Map<String, dynamic>? get defects => _currentDefects;
  double? get testCoverage => _currentTestCoverage;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _service.isConnected;
  
  void _initialize() async {
    try {
      await _service.connect();
      
      // Listen to metrics stream
      _service.metricsStream.listen((metrics) {
        _currentMetrics = metrics;
        _isLoading = false;
        _error = null;
        notifyListeners();
      });
      
      // Listen to defects stream
      _service.defectsStream.listen((defects) {
        _currentDefects = defects;
        notifyListeners();
      });
      
      // Listen to test coverage stream
      _service.testCoverageStream.listen((coverage) {
        _currentTestCoverage = coverage;
        notifyListeners();
      });
      
    } catch (e) {
      _error = 'Failed to initialize real-time QA service: \$e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      if (!_service.isConnected) {
        await _service.connect();
      }
      
      // Send refresh command
      await _service.sendCommand('refresh', {});
      
    } catch (e) {
      _error = 'Refresh failed: \$e';
      _isLoading = false;
      notifyListeners();
    }
  }
  
  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }
}