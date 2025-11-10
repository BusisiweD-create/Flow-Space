// ignore_for_file: avoid_print, unused_import, unused_element, unused_catch_stack, prefer_const_constructors

import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../services/mock_data_service.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';
import '../utils/error_handler.dart';

class DashboardState {
  final List<Deliverable> deliverables;
  final List<Sprint> sprints;
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
    List<Deliverable>? deliverables,
    List<Sprint>? sprints,
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
  DashboardNotifier() : super(DashboardState(deliverables: [], sprints: []));

  Future<void> loadDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Always try to use real data first - only fallback to mock data as last resort
      if (!ApiService.isAuthenticated) {
        print('DashboardProvider: User not authenticated, cannot fetch real data');
        throw AppError.authentication('User not authenticated');
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
          .map((data) => Deliverable.fromJson(data))
          .toList();
      final sprints = (sprintsData is List ? sprintsData : [])
          .map((data) => Sprint.fromJson(data))
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
      print('DashboardProvider: Error loading dashboard data: \$e');
      print('Stack trace: \$stackTrace');
      
      // Only use mock data as a last resort for specific error types
      if (e is AppError && e.type == AppErrorType.authentication) {
        // Authentication errors - show proper error message
        state = state.copyWith(
          isLoading: false,
          error: 'Authentication required. Please log in to view dashboard data.',
        );
      } else if (e is AppError && e.type == AppErrorType.network) {
        // Network errors - show connection error
        state = state.copyWith(
          isLoading: false,
          error: 'Network connection error. Please check your internet connection.',
        );
      } else {
        // Other errors - use minimal mock data for basic functionality
        print('DashboardProvider: Falling back to minimal mock data for basic UI');
        final mockService = MockDataService();
        final deliverables = mockService.getMockDeliverables().take(2).toList();
        final sprints = mockService.getMockSprints().take(1).toList();
        final analyticsData = {};
        
        state = state.copyWith(
          deliverables: deliverables,
          sprints: sprints,
          analyticsData: analyticsData as Map<String, dynamic>,
          isLoading: false,
          error: 'Unable to load real data. Showing limited demo data.',
        );
      }
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

extension on Object {
  map(Sprint Function(dynamic data) param0) {}
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);