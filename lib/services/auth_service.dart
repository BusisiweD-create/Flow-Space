import 'package:flutter/foundation.dart';
import 'package:khono/models/user.dart';
import 'package:khono/models/user_role.dart';
import 'backend_api_service.dart';
import 'api_client.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() {
    // Automatically initialize when first accessed
    _instance._ensureInitialized();
    return _instance;
  }
  AuthService._internal();

  final BackendApiService _apiService = BackendApiService();
  User? _currentUser;
  bool _isAuthenticated = false;
  bool _isInitialized = false;
  String? _lastAuthError;

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
      _isInitialized = true;
    }
  }

  // Getters
  User? get currentUser => _currentUser;
  Future<User?> getCurrentUser() async {
    if (_currentUser == null) {
      await _loadCurrentUser();
    }
    return _currentUser;
  }
  bool get isAuthenticated => _isAuthenticated;
  UserRole? get currentUserRole => _currentUser?.role;
  String? get accessToken => _apiService.accessToken;
  String? get lastAuthError => _lastAuthError;

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
        if (_currentUser != null && _currentUser!.isActive) {
          _isAuthenticated = true;
          debugPrint('User session restored: ${_currentUser!.name} (${_currentUser!.roleDisplayName})');
        } else {
          await _apiService.signOut();
          _currentUser = null;
          _isAuthenticated = false;
          _lastAuthError = 'Your account is inactive. Please contact support.';
          debugPrint('Inactive user blocked from session restore');
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
        if (_currentUser != null && _currentUser!.isActive) {
          _isAuthenticated = true;
          debugPrint('User signed in: ${_currentUser!.name} (${_currentUser!.roleDisplayName})');
          return true;
        } else {
          await _apiService.signOut();
          _currentUser = null;
          _isAuthenticated = false;
          _lastAuthError = 'Your account is inactive. Please contact support.';
          debugPrint('Inactive user login blocked');
          return false;
        }
      } else {
        debugPrint('Sign in failed: ${response.error}');
        _lastAuthError = response.error;
      }
      return false;
    } catch (e) {
      debugPrint('Sign in error: $e');
      _lastAuthError = 'Login failed. Please try again.';
      return false;
    }
  }

  Future<Map<String, dynamic>> signUp(String email, String password, String fullName, UserRole role) async {
    try {
      final response = await _apiService.signUp(email, password, fullName, role);
      
      if (response.isSuccess && response.data != null) {
        _currentUser = _apiService.parseUserFromResponse(response);
        if (_currentUser != null && _currentUser!.isActive) {
          _isAuthenticated = true;
          debugPrint('User signed up: ${_currentUser!.name} (${_currentUser!.roleDisplayName})');
          return {'success': true};
        } else {
          await _apiService.signOut();
          _currentUser = null;
          _isAuthenticated = false;
          _lastAuthError = 'Your account is inactive. Please contact support.';
          debugPrint('Inactive user signup blocked');
          return {'success': false, 'error': _lastAuthError!};
        }
      } else {
        debugPrint('Sign up failed: ${response.error}');
        return {'success': false, 'error': response.error ?? 'Registration failed'};
      }
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

  // ignore: strict_top_level_inference
  get token => null;

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

  Future<ApiResponse> resendVerificationEmail(String email) async {
    try {
      return await _apiService.resendVerificationEmail(email);
    } catch (e) {
      debugPrint('Resend verification email error: $e');
      return ApiResponse.error('Failed to resend verification email');
    }
  }

  Future<ApiResponse> verifyEmail(String email, String verificationCode) async {
    try {
      return await _apiService.verifyEmail(email, verificationCode);
    } catch (e) {
      debugPrint('Verify email error: $e');
      return ApiResponse.error('Failed to verify email');
    }
  }

  bool canAccessRoute(String route) {
    return _isAuthenticated;
  }
}
