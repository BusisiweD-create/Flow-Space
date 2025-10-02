// ignore_for_file: unused_element

import 'package:flutter/foundation.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class ApiAuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _user != null;

  // Initialize the provider
  Future<void> initialize() async {
    _setLoading(true);
    try {
      await ApiService.initialize();
      
      // Check if user is already authenticated (has valid tokens)
      if (ApiService.isAuthenticated) {
        // User is authenticated, we can try to get user info
        // For now, we'll just set a minimal user object
        // In a real implementation, you might fetch user profile
        _user = User(
          id: int.parse(ApiService.currentUserId ?? '0'),
          email: 'authenticated@user.com', // This would come from token claims
          firstName: 'User',
          lastName: 'Authenticated',
          company: 'Unknown',
          role: 'user',
          isActive: true,
          isVerified: true,
          createdAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      _setError('Failed to initialize API service: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Sign up method
  Future<bool> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String company,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

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
      _user = tokenResponse.user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sign up failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign in method
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final tokenResponse = await ApiService.signIn(email, password);
      _user = tokenResponse.user;
      notifyListeners();
      return true;
    } catch (e) {
      _setError('Sign in failed: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Sign out method
  Future<void> signOut() async {
    _user = null;
    _clearError();
    // Clear authentication tokens
    await ApiService.clearTokens();
    notifyListeners();
  }

  // Get user profile
  Map<String, dynamic>? get userProfile {
    if (_user == null) return null;
    
    return {
      'id': _user!.id,
      'email': _user!.email,
      'first_name': _user!.firstName,
      'last_name': _user!.lastName,
      'company': _user!.company,
      'role': _user!.role,
      'created_at': _user!.createdAt.toIso8601String(),
    };
  }

  // Helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
