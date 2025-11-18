import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../services/backend_api_service.dart';
import '../services/api_client.dart';
import '../services/error_handler.dart';
import '../models/user.dart';

// Service providers for dependency injection
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final backendApiServiceProvider = Provider<BackendApiService>((ref) {
  return BackendApiService();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

final errorHandlerProvider = Provider<ErrorHandler>((ref) {
  return ErrorHandler();
});

// User state provider
final currentUserProvider = NotifierProvider<UserNotifier, User?>(() {
  return UserNotifier();
});

final isAuthenticatedProvider = NotifierProvider<AuthNotifier, bool>(() {
  return AuthNotifier();
});

// User state notifier
class UserNotifier extends Notifier<User?> {
  @override
  User? build() => null;
  
  void setUser(User? user) {
    state = user;
  }
  
  void clearUser() {
    state = null;
  }
}

// Auth state notifier
class AuthNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  
  void setAuthenticated(bool isAuthenticated) {
    state = isAuthenticated;
  }
}