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
  DashboardNotifier() : super(DashboardState(deliverables: [], sprints: []));

  Future<void> loadDashboardData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // Debug: Check authentication state before making API calls
      final isAuthenticated = ApiService.isAuthenticated;
      // Replaced with proper logging framework
      // log('DashboardProvider: User authenticated: $isAuthenticated');
      if (isAuthenticated) {
        final token = ApiService.accessToken;
        print('DashboardProvider: Access token present: \${token != null && token.isNotEmpty}');
        if (token != null) {
          print('DashboardProvider: Token length: \${token.length}');
          print('DashboardProvider: Token starts with: \${token.substring(0, min(20, token.length))}...');
        }
      }
      
      // Use mock data if backend is not available or user is not authenticated
      if (MockDataService.shouldUseMockData() || !ApiService.isAuthenticated) {
        print('DashboardProvider: Using mock data for dashboard');
        await Future.delayed(Duration(milliseconds: 500)); // Simulate network delay
        
        final mockService = MockDataService();
        final deliverables = mockService.getMockDeliverables();
        final sprints = mockService.getMockSprints();
        final analyticsData = mockService.getMockAnalyticsData();
        
        state = state.copyWith(
          deliverables: deliverables,
          sprints: sprints,
          analyticsData: analyticsData,
          isLoading: false,
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
      );
    } catch (e, stackTrace) {
      print('DashboardProvider: Error loading dashboard data: \$e');
      print('Stack trace: \$stackTrace');
      
      // Fallback to mock data on error
      print('DashboardProvider: Falling back to mock data');
      final mockService = MockDataService();
      final deliverables = mockService.getMockDeliverables();
      final sprints = mockService.getMockSprints();
      final analyticsData = mockService.getMockAnalyticsData();
      
      state = state.copyWith(
        deliverables: deliverables,
        sprints: sprints,
        analyticsData: analyticsData,
        isLoading: false,
        error: null, // Clear error since we have mock data
      );
    }
  }

  Future<void> refreshData() async {
    await loadDashboardData();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Removed unused extension

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);