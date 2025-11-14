import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

// Simple auth state for demo purposes
class AuthState {
  final bool isLoading;
  final String? error;
  final String? userEmail;

  AuthState({
    this.isLoading = false,
    this.error,
    this.userEmail,
  });

  AuthState copyWith({
    bool? isLoading,
    String? error,
    String? userEmail,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userEmail: userEmail ?? this.userEmail,
    );
  }
}

class SimpleAuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => AuthState();

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await ApiService.signIn(email: email, password: password);
      
      if (response != null && response['user'] != null) {
        state = state.copyWith(
          isLoading: false,
          userEmail: email,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Invalid email or password',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign in failed: $e',
      );
    }
  }

  Future<void> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String company,
    required String role,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final response = await ApiService.signUp(
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        company: company,
        role: role,
      );
      
      if (response != null && response['user'] != null) {
        state = state.copyWith(
          isLoading: false,
          userEmail: email,
        );
      } else {
        final errorMessage = response?['message'] ?? response?['error'] ?? 'Registration failed. Please check your details.';
        state = state.copyWith(
          isLoading: false,
          error: errorMessage,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed: $e',
      );
    }
  }





  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      state = state.copyWith(
        isLoading: false,
        userEmail: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Sign out failed: $e',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authStateProvider = NotifierProvider<SimpleAuthNotifier, AuthState>(() {
  return SimpleAuthNotifier();
});
