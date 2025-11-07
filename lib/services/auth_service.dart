import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import 'backend_api_service.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final BackendApiService _apiService = BackendApiService();
  User? _currentUser;
  bool _isAuthenticated = false;

  // Getters
  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get currentUserRole => _currentUser?.role;
  String? get accessToken => _apiService.accessToken;

  // Initialize the service
  Future<void> initialize() async {
    await _apiService.initialize();
    await _loadCurrentUser();
  }

  // Load current user from stored session
  Future<void> _loadCurrentUser() async {
    try {
      final response = await _apiService.getCurrentUser();
      if (response.isSuccess && response.data != null) {
        _currentUser = _apiService.parseUserFromResponse(response);
        _isAuthenticated = _currentUser != null;
        if (_isAuthenticated) {
          debugPrint('User session restored: ${_currentUser!.name} (${_currentUser!.roleDisplayName})');
        }
      }
    } catch (e) {
      debugPrint('Error loading current user: $e');
      _currentUser = null;
      _isAuthenticated = false;
    }
  }

  // Authentication methods
  Future<bool> signIn(String email, String password) async {
    try {
      final response = await _apiService.signIn(email, password);
      
      if (response.isSuccess && response.data != null) {
        // Extract user data from the nested "user" field in login response
        final userData = response.data!['user'] ?? response.data!;
        final userResponse = ApiResponse.success(userData, response.statusCode);
        
        _currentUser = _apiService.parseUserFromResponse(userResponse);
        _isAuthenticated = _currentUser != null;
        
        if (_isAuthenticated) {
          debugPrint('User signed in: ${_currentUser!.name} (${_currentUser!.roleDisplayName})');
          return true;
        }
      } else {
        debugPrint('Sign in failed: ${response.error}');
      }
      return false;
    } catch (e) {
      debugPrint('Sign in error: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>> signUp(String email, String password, String name, UserRole role) async {
    try {
      final response = await _apiService.signUp(email, password, name, role);
      
      if (response.isSuccess && response.data != null) {
        _currentUser = _apiService.parseUserFromResponse(response);
        _isAuthenticated = _currentUser != null;
        
        if (_isAuthenticated) {
          debugPrint('User signed up: ${_currentUser!.name} (${_currentUser!.roleDisplayName})');
          return {'success': true};
        }
      } else {
        debugPrint('Sign up failed: ${response.error}');
        return {'success': false, 'error': response.error ?? 'Registration failed'};
      }
      return {'success': false, 'error': 'Registration failed'};
    } catch (e) {
      debugPrint('Sign up error: $e');
      return {'success': false, 'error': 'Registration failed: $e'};
    }
  }

  Future<void> signOut() async {
    try {
      await _apiService.signOut();
    } catch (e) {
      debugPrint('Sign out error: $e');
    } finally {
      _currentUser = null;
      _isAuthenticated = false;
      debugPrint('User signed out');
    }
  }

  // Permission checking
  bool hasPermission(String permissionName) {
    if (!_isAuthenticated || _currentUser == null) return false;
    return _currentUser!.hasPermission(permissionName);
  }

  bool canCreateDeliverable() => hasPermission('create_deliverable');
  bool canEditDeliverable() => hasPermission('edit_deliverable');
  bool canSubmitForReview() => hasPermission('submit_for_review');
  bool canApproveDeliverable() => hasPermission('approve_deliverable');
  bool canViewTeamDashboard() => hasPermission('view_team_dashboard');
  bool canViewClientReview() => hasPermission('view_client_review');
  bool canManageUsers() => hasPermission('manage_users');
  bool canViewAuditLogs() => hasPermission('view_audit_logs');
  bool canOverrideReadinessGate() => hasPermission('override_readiness_gate');
  bool canViewAllDeliverables() => hasPermission('view_all_deliverables');

  // Role checking
  bool get isTeamMember => _currentUser?.isTeamMember ?? false;
  bool get isDeliveryLead => _currentUser?.isDeliveryLead ?? false;
  bool get isClientReviewer => _currentUser?.isClientReviewer ?? false;
  bool get isSystemAdmin => _currentUser?.isSystemAdmin ?? false;

  // Additional authentication methods
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.changePassword(currentPassword, newPassword);
      return response.isSuccess;
    } catch (e) {
      debugPrint('Change password error: $e');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _apiService.forgotPassword(email);
      return response.isSuccess;
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return false;
    }
  }

  Future<bool> resetPassword(String token, String newPassword) async {
    try {
      final response = await _apiService.resetPassword(token, newPassword);
      return response.isSuccess;
    } catch (e) {
      debugPrint('Reset password error: $e');
      return false;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      final response = await _apiService.updateProfile(updates);
      if (response.isSuccess && response.data != null) {
        _currentUser = _apiService.parseUserFromResponse(response);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return false;
    }
  }

  // Get all available roles for registration
  List<UserRole> getAvailableRoles() {
    return UserRole.values;
  }

  // Get role permissions
  List<String> getCurrentUserPermissions() {
    if (_currentUser == null) return [];
    return PermissionManager.getPermissionNamesForRole(_currentUser!.role);
  }

  // Check if user can access a specific route
  bool canAccessRoute(String route) {
    if (!_isAuthenticated) return false;

    switch (route) {
      case '/dashboard':
        return true; // All authenticated users can access dashboard
      case '/deliverable-setup':
      case '/enhanced-deliverable-setup':
        return canCreateDeliverable();
      case '/sprint-console':
        return hasPermission('manage_sprints');
      case '/client-review':
      case '/enhanced-client-review':
        return canViewClientReview();
      case '/report-repository':
        return isDeliveryLead || isSystemAdmin || isClientReviewer;
      case '/notification-center':
        return true; // All users can access notifications
      case '/approvals':
        return canApproveDeliverable() || isDeliveryLead;
      case '/repository':
        return isDeliveryLead || isSystemAdmin || isTeamMember || isClientReviewer;
      default:
        return true; // Allow access to other routes by default
    }
  }

  // Email verification methods
  Future<ApiResponse> resendVerificationEmail(String email) async {
    try {
      final response = await _apiService.resendVerificationEmail(email);
      if (response.isSuccess) {
        debugPrint('Verification email sent successfully');
      }
      return response;
    } catch (e) {
      debugPrint('Resend verification email error: $e');
      return ApiResponse.error('Failed to resend verification email: $e');
    }
  }

  Future<ApiResponse> verifyEmail(String email, String verificationCode) async {
    try {
      final response = await _apiService.verifyEmail(email, verificationCode);
      if (response.isSuccess && response.data != null) {
        debugPrint('Email verified successfully');
        
        // Extract JWT token from verification response
        final data = response.data!;
        final token = data['token'];
        final userData = data['user'];
        final expiresIn = data['expires_in'] ?? 86400;
        
        if (token != null) {
          // Save the JWT token
          final expiry = DateTime.now().add(Duration(seconds: expiresIn));
          await _apiService.saveTokens(token, '', expiry);
          debugPrint('JWT token saved after email verification');
        }
        
        // Set current user
        if (userData != null) {
          _currentUser = User.fromJson(userData);
          _isAuthenticated = true;
          debugPrint('✅ Loaded user: ${_currentUser!.name} (${_currentUser!.email})');
        }
      }
      return response;
    } catch (e) {
      debugPrint('Email verification error: $e');
      return ApiResponse.error('Email verification failed: $e');
    }
  }

  Future<ApiResponse> checkEmailVerificationStatus(String email) async {
    try {
      final response = await _apiService.checkEmailVerificationStatus(email);
      return response;
    } catch (e) {
      debugPrint('Check verification status error: $e');
      return ApiResponse.error('Failed to check verification status: $e');
    }
  }
}
