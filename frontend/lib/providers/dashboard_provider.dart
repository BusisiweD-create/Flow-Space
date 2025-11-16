// ignore_for_file: avoid_print, unused_import, unused_element, unused_catch_stack, prefer_const_constructors

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
// Models replaced with simple maps for compatibility with API responses

class DashboardState {
  final List<Map<String, dynamic>> deliverables;
  final List<Map<String, dynamic>> sprints;
  final Map<String, dynamic> analyticsData;
  final bool isLoading;
  final String? error;

  DashboardState({
    required this.deliverables,
    required this.sprints,
    this.analyticsData = const {},
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    List<Map<String, dynamic>>? deliverables,
    List<Map<String, dynamic>>? sprints,
    Map<String, dynamic>? analyticsData,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      deliverables: deliverables ?? this.deliverables,
      sprints: sprints ?? this.sprints,
      analyticsData: analyticsData ?? this.analyticsData,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  DashboardNotifier() : super(DashboardState(deliverables: [], sprints: [])) {
    _initializeRealtimeListeners();
  }

  void _initializeRealtimeListeners() {
    // Set up real-time event listeners with dynamic parameter types
    realtimeService.on('deliverable_created', (data) => _handleDeliverableCreated(Deliverable.fromJson(data)));
    realtimeService.on('deliverable_updated', (data) => _handleDeliverableUpdated(Deliverable.fromJson(data)));
    realtimeService.on('deliverable_deleted', (data) => _handleDeliverableDeleted(data as String));
    realtimeService.on('deliverable_status_changed', _handleDeliverableStatusChanged);
    
    realtimeService.on('sprint_created', (data) => _handleSprintCreated(Sprint.fromJson(data)));
    realtimeService.on('sprint_updated', (data) => _handleSprintUpdated(Sprint.fromJson(data)));
    realtimeService.on('sprint_deleted', (data) => _handleSprintDeleted(data as String));
    
    realtimeService.on('analytics_updated', _handleAnalyticsUpdated);
  }

  Future<void> loadDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Debug: Check authentication state before making API calls
      final isAuthenticated = ApiService.isAuthenticated;
      // Replaced with proper logging framework
      // log('DashboardProvider: User authenticated: $isAuthenticated');
      if (isAuthenticated) {
        final token = ApiService.accessToken;
        // print('DashboardProvider: Access token present: \${token != null && token.isNotEmpty}');
        if (token != null) {
          // print('DashboardProvider: Token length: \${token.length}');
          // print('DashboardProvider: Token starts with: \${token.substring(0, min(20, token.length))}...');
        }
      }
      
      // Only use real API data
      if (!ApiService.isAuthenticated) {
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication required. Please log in to view dashboard data.',
        );
        return;
      }
      
      // Fetch deliverables, sprints, and analytics data concurrently
      final deliverablesFuture = ApiService.getDeliverables(limit: 10);
      final sprintsFuture = ApiService.getSprints(limit: 10);
      final analyticsFuture = ApiService.getDashboardData();
      
      final results = await Future.wait([deliverablesFuture, sprintsFuture, analyticsFuture]);
      
      final deliverablesData = results[0];
      final sprintsData = results[1];
      final analyticsData = results[2];
      
      // Convert API data to model objects with null safety
      final deliverables = (deliverablesData is List ? deliverablesData : [])
          .map((data) => Map<String, dynamic>.from(data as Map))
          .toList();
      final sprints = (sprintsData is List ? sprintsData : [])
          .map((data) => Map<String, dynamic>.from(data as Map))
          .toList();
      
      state = state.copyWith(
        deliverables: deliverables,
        sprints: sprints,
        analyticsData: analyticsData as Map<String, dynamic>,
        isLoading: false,
        error: null,
      );
      
      print('DashboardProvider: Successfully loaded real data - '
          '${deliverables.length} deliverables, ${sprints.length} sprints');
      
    } catch (e, stackTrace) {
      // print('DashboardProvider: Error loading dashboard data: \$e');
      // print('Stack trace: \$stackTrace');
      
      // Show proper error message
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data. Please check your connection and try again.',
      );
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  // Real-time event handlers
  void _handleDeliverableCreated(Deliverable deliverable) {
    final currentDeliverables = List<Deliverable>.from(state.deliverables);
    currentDeliverables.insert(0, deliverable);
    state = state.copyWith(deliverables: currentDeliverables);
  }

  void _handleDeliverableUpdated(Deliverable updatedDeliverable) {
    final currentDeliverables = List<Deliverable>.from(state.deliverables);
    final index = currentDeliverables.indexWhere((d) => d.id == updatedDeliverable.id);
    if (index != -1) {
      currentDeliverables[index] = updatedDeliverable;
      state = state.copyWith(deliverables: currentDeliverables);
    }
  }

  void _handleDeliverableDeleted(String deliverableId) {
    final currentDeliverables = List<Deliverable>.from(state.deliverables);
    currentDeliverables.removeWhere((d) => d.id == deliverableId);
    state = state.copyWith(deliverables: currentDeliverables);
  }

  void _handleDeliverableStatusChanged(dynamic data) {
    final deliverableId = data['deliverableId'];
    final newStatus = data['newStatus'];
    
    final currentDeliverables = List<Deliverable>.from(state.deliverables);
    final index = currentDeliverables.indexWhere((d) => d.id == deliverableId);
    if (index != -1) {
      final updatedDeliverable = currentDeliverables[index].copyWith(status: newStatus);
      currentDeliverables[index] = updatedDeliverable;
      state = state.copyWith(deliverables: currentDeliverables);
    }
  }

  void _handleSprintCreated(Sprint sprint) {
    final currentSprints = List<Sprint>.from(state.sprints);
    currentSprints.insert(0, sprint);
    state = state.copyWith(sprints: currentSprints);
  }

  void _handleSprintUpdated(Sprint updatedSprint) {
    final currentSprints = List<Sprint>.from(state.sprints);
    final index = currentSprints.indexWhere((s) => s.id == updatedSprint.id);
    if (index != -1) {
      currentSprints[index] = updatedSprint;
      state = state.copyWith(sprints: currentSprints);
    }
  }

  void _handleSprintDeleted(String sprintId) {
    final currentSprints = List<Sprint>.from(state.sprints);
    currentSprints.removeWhere((s) => s.id == sprintId);
    state = state.copyWith(sprints: currentSprints);
  }

  void _handleAnalyticsUpdated(dynamic analyticsData) {
    state = state.copyWith(analyticsData: analyticsData);
  }

  @override
  void dispose() {
    // Clean up real-time listeners
    realtimeService.offAll('deliverable_created');
    realtimeService.offAll('deliverable_updated');
    realtimeService.offAll('deliverable_deleted');
    realtimeService.offAll('deliverable_status_changed');
    realtimeService.offAll('sprint_created');
    realtimeService.offAll('sprint_updated');
    realtimeService.offAll('sprint_deleted');
    realtimeService.offAll('analytics_updated');
    super.dispose();
  }
}

// Removed unused extension

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);