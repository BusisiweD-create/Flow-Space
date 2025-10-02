import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';

class DashboardState {
  final List<Deliverable> deliverables;
  final List<Sprint> sprints;
  final bool isLoading;
  final String? error;

  DashboardState({
    required this.deliverables,
    required this.sprints,
    this.isLoading = false,
    this.error,
  });

  DashboardState copyWith({
    List<Deliverable>? deliverables,
    List<Sprint>? sprints,
    bool? isLoading,
    String? error,
  }) {
    return DashboardState(
      deliverables: deliverables ?? this.deliverables,
      sprints: sprints ?? this.sprints,
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
      
      // Fetch deliverables and sprints concurrently
      final deliverablesFuture = ApiService.getDeliverables(limit: 10);
      final sprintsFuture = ApiService.getSprints(limit: 10);
      
      final results = await Future.wait([deliverablesFuture, sprintsFuture]);
      
      final deliverablesData = results[0];
      final sprintsData = results[1];
      
      // Convert API data to model objects
      final deliverables = deliverablesData.map((data) => Deliverable.fromJson(data)).toList();
      final sprints = sprintsData.map((data) => Sprint.fromJson(data)).toList();
      
      state = state.copyWith(
        deliverables: deliverables,
        sprints: sprints,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load dashboard data: $e',
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

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>(
  (ref) => DashboardNotifier(),
);