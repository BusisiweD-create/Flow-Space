// ignore_for_file: unused_local_variable

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import '../models/user.dart';

// API Authentication State
class ApiAuthState {
  final bool isLoading;
  final String? error;
  final User? user;

  ApiAuthState({
    this.isLoading = false,
    this.error,
    this.user,
  });

  ApiAuthState copyWith({
    bool? isLoading,
    String? error,
    User? user,
  }) {
    return ApiAuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      user: user ?? this.user,
    );
  }
}

// API Authentication Notifier
class ApiAuthNotifier extends StateNotifier<ApiAuthState> {
  ApiAuthNotifier() : super(ApiAuthState());

  // Initialize authentication
  Future<void> initialize() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.initialize();
      
      // Check if user is already authenticated
      if (ApiService.isAuthenticated) {
        // User is authenticated, fetch user profile
        await _fetchUserProfile();
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize authentication: $e',
      );
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Sign up method
  Future<void> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String company,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final userCreate = UserCreate(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        company: company,
        role: role,
      );
      
      final tokenResponse = await ApiService.signUp(userCreate);
      state = state.copyWith(user: tokenResponse.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign up failed: $e',
      );
    }
  }

  // Sign in method
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final tokenResponse = await ApiService.signIn(email, password);
      state = state.copyWith(user: tokenResponse.user, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign in failed: $e',
      );
    }
  }

  // Sign out method
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ApiService.clearTokens();
      state = state.copyWith(user: null, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed: $e',
      );
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Fetch user profile
  Future<void> _fetchUserProfile() async {
    try {
      final user = await ApiService.fetchUserProfile();
      // For now, create a minimal user object from token claims
      final userFromProfile = User(
        id: int.parse(ApiService.currentUserId ?? '0'),
        email: ApiService.currentUserEmail ?? 'authenticated@user.com',
        firstName: 'User',
        lastName: 'Authenticated',
        company: 'Unknown',
        role: 'user',
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
      );
      state = state.copyWith(user: user);
    } catch (e) {
      state = state.copyWith(error: 'Failed to fetch user profile: $e');
    }
  }

  Future<void> requestPasswordReset(String trim) async {}

  Future<void> signInWithGoogle() async {}

  Future<void> resendVerificationEmail() async {}
}

// Riverpod provider for API authentication
final apiAuthProvider = StateNotifierProvider<ApiAuthNotifier, ApiAuthState>((ref) {
  return ApiAuthNotifier();
});

// Current user provider
final apiCurrentUserProvider = StreamProvider<User?>((ref) {
  final authState = ref.watch(apiAuthProvider);
  return Stream.value(authState.user);
});