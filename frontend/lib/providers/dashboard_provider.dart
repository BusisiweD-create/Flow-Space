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
        // print('DashboardProvider: Access token present: \${token != null && token.isNotEmpty}');
        if (token != null) {
          // print('DashboardProvider: Token length: \${token.length}');
          // print('DashboardProvider: Token starts with: \${token.substring(0, min(20, token.length))}...');
        }
      }
      
      
      
      // Fetch deliverables, sprints, and analytics data concurrently
      final deliverablesFuture = ApiService.getDeliverables(limit: 10);
      final sprintsFuture = ApiService.getSprints(limit: 10);
      final analyticsFuture = ApiService.getDashboardData();
      
      final results = await Future.wait([deliverablesFuture, sprintsFuture, analyticsFuture]);
      
      final deliverablesData = results[0];
      final sprintsData = results[1];
      final analyticsData = results[2];
      
      final deliverables = (deliverablesData is List ? deliverablesData : [])
          .map((item) => item is Map
              ? Map<String, dynamic>.from(item)
              : (() {
                  try {
                    final m = (item as dynamic).toJson();
                    return Map<String, dynamic>.from(m);
                  } catch (_) {
                    return <String, dynamic>{};
                  }
                })(),)
          .where((m) => m.isNotEmpty)
          .toList();
      final sprints = (sprintsData is List ? sprintsData : [])
          .map((item) => item is Map
              ? Map<String, dynamic>.from(item)
              : (() {
                  try {
                    final m = (item as dynamic).toJson();
                    return Map<String, dynamic>.from(m);
                  } catch (_) {
                    return <String, dynamic>{};
                  }
                })(),)
          .where((m) => m.isNotEmpty)
          .toList();
      
      state = state.copyWith(
        deliverables: deliverables,
        sprints: sprints,
        analyticsData: analyticsData is Map<String, dynamic> ? analyticsData : <String, dynamic>{},
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

  // Real-time handlers removed for now
}

// Removed unused extension

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);