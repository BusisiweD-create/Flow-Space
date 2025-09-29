import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class SimpleAuthNotifier extends StateNotifier<AuthState> {
  SimpleAuthNotifier() : super(AuthState());

  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple validation for demo
    if (email.isNotEmpty && password.length >= 6) {
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
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    // Simple validation for demo
    if (email.isNotEmpty && password.length >= 8) {
      state = state.copyWith(
        isLoading: false,
        userEmail: email,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: 'Registration failed. Please check your details.',
      );
    }
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));
    
    state = state.copyWith(
      isLoading: false,
      userEmail: 'demo@google.com',
    );
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    state = state.copyWith(isLoading: false);
  }

  Future<void> resendEmailVerification() async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    state = state.copyWith(isLoading: false);
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    // Simulate API call
    await Future.delayed(const Duration(seconds: 1));
    
    state = state.copyWith(
      isLoading: false,
      userEmail: null,
    );
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

final authStateProvider = StateNotifierProvider<SimpleAuthNotifier, AuthState>((ref) {
  return SimpleAuthNotifier();
});

// Mock current user provider
final currentUserProvider = StreamProvider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return Stream.value(authState.userEmail);
});
