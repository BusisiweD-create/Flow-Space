import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../services/qa_realtime_service.dart';
import '../services/auth_service.dart';

class QAState {
  final List<Map<String, dynamic>> testQueue;
  final Map<String, dynamic> qualityMetrics;
  final List<Map<String, dynamic>> bugReports;
  final Map<String, dynamic> testCoverage;
  final bool isLoading;
  final String? error;

  QAState({
    required this.testQueue,
    required this.qualityMetrics,
    required this.bugReports,
    required this.testCoverage,
    this.isLoading = false,
    this.error,
  });

  QAState copyWith({
    List<Map<String, dynamic>>? testQueue,
    Map<String, dynamic>? qualityMetrics,
    List<Map<String, dynamic>>? bugReports,
    Map<String, dynamic>? testCoverage,
    bool? isLoading,
    String? error,
  }) {
    return QAState(
      testQueue: testQueue ?? this.testQueue,
      qualityMetrics: qualityMetrics ?? this.qualityMetrics,
      bugReports: bugReports ?? this.bugReports,
      testCoverage: testCoverage ?? this.testCoverage,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class QANotifier extends Notifier<QAState> {
  QARealtimeService? _realtimeService;
  
  @override
  QAState build() {
    return QAState(
      testQueue: [],
      qualityMetrics: {},
      bugReports: [],
      testCoverage: {},
      isLoading: false,
      error: null,
    );
  }
  
  QANotifier() {
    _initializeRealtimeListeners();
  }
  
  void _initializeRealtimeListeners() {
    // Listen to metrics stream for quality metrics updates
    _realtimeService?.metricsStream.listen((metrics) {
      _handleQualityMetricsUpdated(metrics);
    });
    
    // Listen to defects stream for bug report updates
    _realtimeService?.defectsStream.listen((defects) {
      // Handle defects updates - this might need to be mapped to bug reports
      _handleBugReportUpdated(defects);
    });
    
    // Listen to test coverage stream
    _realtimeService?.testCoverageStream.listen((coverage) {
      _handleTestCoverageUpdated({'coverage': coverage});
    });
  }

  Future<void> loadQAData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      if (!AuthService().isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication required. Please log in to view QA data.',
        );
        return;
      }
      
      // Fetch QA data concurrently
      final testQueueFuture = ApiService.getTestQueue();
      final qualityMetricsFuture = ApiService.getQualityMetrics();
      final bugReportsFuture = ApiService.getBugReports();
      final testCoverageFuture = ApiService.getTestCoverage();
      
      final results = await Future.wait([
        testQueueFuture,
        qualityMetricsFuture,
        bugReportsFuture,
        testCoverageFuture,
      ]);
      
      state = state.copyWith(
        testQueue: results[0] as List<Map<String, dynamic>>,
        qualityMetrics: results[1] as Map<String, dynamic>,
        bugReports: results[2] as List<Map<String, dynamic>>,
        testCoverage: results[3] as Map<String, dynamic>,
        isLoading: false,
      );
      
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load QA data: $e',
      );
      debugPrint('Error loading QA data: $e');
    }
  }

  Future<void> refreshData() async {
    await loadQAData();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Real-time event handlers
  void _handleQualityMetricsUpdated(dynamic data) {
    final qualityMetrics = Map<String, dynamic>.from(data as Map);
    state = state.copyWith(qualityMetrics: qualityMetrics);
  }

  void _handleBugReportUpdated(dynamic data) {
    final updatedBugReport = Map<String, dynamic>.from(data as Map);
    final currentBugReports = List<Map<String, dynamic>>.from(state.bugReports);
    final index = currentBugReports.indexWhere((report) => report['id'] == updatedBugReport['id']);
    if (index != -1) {
      currentBugReports[index] = updatedBugReport;
      state = state.copyWith(bugReports: currentBugReports);
    }
  }

  void _handleTestCoverageUpdated(dynamic data) {
    final testCoverage = Map<String, dynamic>.from(data as Map);
    state = state.copyWith(testCoverage: testCoverage);
  }
}

final qaDataProvider = NotifierProvider<QANotifier, QAState>((ref) {
  return QANotifier();
} as QANotifier Function(),);