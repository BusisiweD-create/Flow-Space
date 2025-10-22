import 'package:flutter/foundation.dart';
import 'api_client.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../models/deliverable.dart';
import '../models/sprint_metrics.dart';
import '../models/sign_off_report.dart';

class BackendApiService {
  static final BackendApiService _instance = BackendApiService._internal();
  factory BackendApiService() => _instance;
  BackendApiService._internal();

  final ApiClient _apiClient = ApiClient();

  // Getters
  String? get accessToken => _apiClient.accessToken;

  // Initialize the service
  Future<void> initialize() async {
    await _apiClient.initialize();
    debugPrint('Backend API Service initialized');
  }

  // Authentication endpoints
  Future<ApiResponse> signIn(String email, String password) async {
    return await _apiClient.login(email, password);
  }

  Future<ApiResponse> signUp(String email, String password, String name, UserRole role) async {
    return await _apiClient.register(email, password, name, role.name);
  }

  Future<ApiResponse> signOut() async {
    return await _apiClient.logout();
  }

  Future<ApiResponse> getCurrentUser() async {
    return await _apiClient.getCurrentUser();
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> updates) async {
    return await _apiClient.updateProfile(updates);
  }

  Future<ApiResponse> changePassword(String currentPassword, String newPassword) async {
    return await _apiClient.changePassword(currentPassword, newPassword);
  }

  Future<ApiResponse> forgotPassword(String email) async {
    return await _apiClient.forgotPassword(email);
  }

  Future<ApiResponse> resetPassword(String token, String newPassword) async {
    return await _apiClient.resetPassword(token, newPassword);
  }

  // User management endpoints
  Future<ApiResponse> getUsers({int page = 1, int limit = 20, String? search}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    return await _apiClient.get('/users', queryParams: queryParams);
  }

  Future<ApiResponse> getUser(String userId) async {
    return await _apiClient.get('/users/$userId');
  }

  Future<ApiResponse> updateUser(String userId, Map<String, dynamic> updates) async {
    return await _apiClient.put('/users/$userId', body: updates);
  }

  Future<ApiResponse> deleteUser(String userId) async {
    return await _apiClient.delete('/users/$userId');
  }

  Future<ApiResponse> updateUserRole(String userId, UserRole newRole) async {
    return await _apiClient.put('/users/$userId/role', body: {'role': newRole.name});
  }

  // Deliverable endpoints
  Future<ApiResponse> getDeliverables({int page = 1, int limit = 20, String? status, String? search}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    return await _apiClient.get('/deliverables', queryParams: queryParams);
  }

  Future<ApiResponse> getDeliverable(String deliverableId) async {
    return await _apiClient.get('/deliverables/$deliverableId');
  }

  Future<ApiResponse> createDeliverable(Map<String, dynamic> deliverableData) async {
    return await _apiClient.post('/deliverables', body: deliverableData);
  }

  Future<ApiResponse> updateDeliverable(String deliverableId, Map<String, dynamic> updates) async {
    return await _apiClient.put('/deliverables/$deliverableId', body: updates);
  }

  Future<ApiResponse> deleteDeliverable(String deliverableId) async {
    return await _apiClient.delete('/deliverables/$deliverableId');
  }

  Future<ApiResponse> submitDeliverable(String deliverableId) async {
    return await _apiClient.post('/deliverables/$deliverableId/submit');
  }

  Future<ApiResponse> approveDeliverable(String deliverableId, String? comment) async {
    return await _apiClient.post('/deliverables/$deliverableId/approve', body: {
      'comment': comment,
    },);
  }

  Future<ApiResponse> requestChanges(String deliverableId, String changeRequest) async {
    return await _apiClient.post('/deliverables/$deliverableId/request-changes', body: {
      'change_request': changeRequest,
    },);
  }

  // Sprint endpoints
  Future<ApiResponse> getSprints({int page = 1, int limit = 20, String? status}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    return await _apiClient.get('/sprints', queryParams: queryParams);
  }

  Future<ApiResponse> getSprint(String sprintId) async {
    return await _apiClient.get('/sprints/$sprintId');
  }

  Future<ApiResponse> createSprint(Map<String, dynamic> sprintData) async {
    return await _apiClient.post('/sprints', body: sprintData);
  }

  Future<ApiResponse> updateSprint(String sprintId, Map<String, dynamic> updates) async {
    return await _apiClient.put('/sprints/$sprintId', body: updates);
  }

  Future<ApiResponse> deleteSprint(String sprintId) async {
    return await _apiClient.delete('/sprints/$sprintId');
  }

  // Sprint metrics endpoints
  Future<ApiResponse> getSprintMetrics(String sprintId) async {
    return await _apiClient.get('/sprints/$sprintId/metrics');
  }

  Future<ApiResponse> createSprintMetrics(String sprintId, Map<String, dynamic> metricsData) async {
    return await _apiClient.post('/sprints/$sprintId/metrics', body: metricsData);
  }

  Future<ApiResponse> updateSprintMetrics(String sprintId, Map<String, dynamic> updates) async {
    return await _apiClient.put('/sprints/$sprintId/metrics', body: updates);
  }

  // Sign-off report endpoints
  Future<ApiResponse> getSignOffReports({int page = 1, int limit = 20, String? status, String? search}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null && status.isNotEmpty) {
      queryParams['status'] = status;
    }
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    return await _apiClient.get('/sign-off-reports', queryParams: queryParams);
  }

  Future<ApiResponse> getSignOffReport(String reportId) async {
    return await _apiClient.get('/sign-off-reports/$reportId');
  }

  Future<ApiResponse> createSignOffReport(Map<String, dynamic> reportData) async {
    return await _apiClient.post('/sign-off-reports', body: reportData);
  }

  Future<ApiResponse> updateSignOffReport(String reportId, Map<String, dynamic> updates) async {
    return await _apiClient.put('/sign-off-reports/$reportId', body: updates);
  }

  Future<ApiResponse> submitSignOffReport(String reportId) async {
    return await _apiClient.post('/sign-off-reports/$reportId/submit');
  }

  Future<ApiResponse> approveSignOffReport(String reportId, String? comment, String? digitalSignature) async {
    return await _apiClient.post('/sign-off-reports/$reportId/approve', body: {
      'comment': comment,
      'digital_signature': digitalSignature,
    },);
  }

  Future<ApiResponse> requestSignOffChanges(String reportId, String changeRequest) async {
    return await _apiClient.post('/sign-off-reports/$reportId/request-changes', body: {
      'change_request': changeRequest,
    },);
  }

  // Release readiness endpoints
  Future<ApiResponse> getReleaseReadinessChecks(String deliverableId) async {
    return await _apiClient.get('/deliverables/$deliverableId/readiness-checks');
  }

  Future<ApiResponse> updateReadinessCheck(String deliverableId, Map<String, dynamic> checkData) async {
    return await _apiClient.put('/deliverables/$deliverableId/readiness-checks', body: checkData);
  }

  // Notification endpoints
  Future<ApiResponse> getNotifications({int page = 1, int limit = 20, bool? unreadOnly}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (unreadOnly != null) {
      queryParams['unread_only'] = unreadOnly.toString();
    }
    return await _apiClient.get('/notifications', queryParams: queryParams);
  }

  Future<ApiResponse> markNotificationAsRead(String notificationId) async {
    return await _apiClient.put('/notifications/$notificationId/read');
  }

  Future<ApiResponse> markAllNotificationsAsRead() async {
    return await _apiClient.put('/notifications/read-all');
  }

  Future<ApiResponse> deleteNotification(String notificationId) async {
    return await _apiClient.delete('/notifications/$notificationId');
  }

  // Dashboard and analytics endpoints
  Future<ApiResponse> getDashboardData() async {
    return await _apiClient.get('/dashboard');
  }

  Future<ApiResponse> getAnalytics(String type, {Map<String, String>? filters}) async {
    return await _apiClient.get('/analytics/$type', queryParams: filters);
  }

  Future<ApiResponse> getAuditLogs({int skip = 0, int limit = 100, String? action, String? userId}) async {
    final queryParams = <String, String>{
      'skip': skip.toString(),
      'limit': limit.toString(),
    };
    if (action != null && action.isNotEmpty) {
      queryParams['action'] = action;
    }
    if (userId != null && userId.isNotEmpty) {
      queryParams['user_id'] = userId;
    }
    
    // Try the audit logs endpoint
    final response = await _apiClient.get('/audit-logs', queryParams: queryParams);
    
    // If the endpoint doesn't exist or returns error, provide mock data for development
    if (!response.isSuccess) {
      debugPrint('Audit logs endpoint not available, returning mock data');
      return ApiResponse.success(_getMockAuditLogs(skip, limit, action, userId), 200);
    }
    
    return response;
  }

  // File upload endpoints
  Future<ApiResponse> uploadFile(String filePath, String fileName, String fileType) async {
    // This would typically use a multipart request
    // For now, we'll return a mock response
    return ApiResponse.success({
      'file_id': 'file_${DateTime.now().millisecondsSinceEpoch}',
      'file_name': fileName,
      'file_url': 'https://api.flownet.works/files/$fileName',
    }, 200,);
  }

  Future<ApiResponse> deleteFile(String fileId) async {
    return await _apiClient.delete('/files/$fileId');
  }

  // System configuration endpoints
  Future<ApiResponse> getSystemSettings() async {
    return await _apiClient.get('/system/settings');
  }

  Future<ApiResponse> updateSystemSettings(Map<String, dynamic> settings) async {
    return await _apiClient.put('/system/settings', body: settings);
  }

  Future<ApiResponse> getHealthCheck() async {
    return await _apiClient.get('/health');
  }

  // System administration endpoints
  Future<ApiResponse> createBackup() async {
    return await _apiClient.post('/system/backup');
  }

  Future<ApiResponse> restoreBackup() async {
    return await _apiClient.post('/system/restore');
  }

  Future<ApiResponse> clearCache() async {
    return await _apiClient.post('/system/clear-cache');
  }

  Future<ApiResponse> optimizeDatabase() async {
    return await _apiClient.post('/system/optimize-database');
  }

  Future<ApiResponse> runDiagnostics() async {
    return await _apiClient.get('/system/diagnostics');
  }

  // Email verification endpoints
  Future<ApiResponse> resendVerificationEmail(String email) async {
    return await _apiClient.post('/auth/resend-verification', body: {
      'email': email,
    },);
  }

  Future<ApiResponse> verifyEmail(String email, String verificationCode) async {
    return await _apiClient.post('/auth/verify-email', body: {
      'email': email,
      'verification_code': verificationCode,
    },);
  }

  Future<ApiResponse> checkEmailVerificationStatus(String email) async {
    return await _apiClient.get('/auth/verification-status', queryParams: {
      'email': email,
    },);
  }

  // Helper methods for data transformation
  User? parseUserFromResponse(ApiResponse response) {
    if (!response.isSuccess || response.data == null) {
      debugPrint('Response not successful or data is null');
      return null;
    }
    
    try {
      // Debug: print the entire response structure
      debugPrint('Full response data: ${response.data}');
      
      // The user data might be nested under 'user' key or at the root level
      // Handle different response structures from different endpoints
      final userData = response.data!['user'] ?? response.data!;
      
      if (userData == null || userData.isEmpty) {
        debugPrint('No user data found in response');
        return null;
      }
      
      debugPrint('User data from response: $userData');
      debugPrint('User ID: ${userData['id']}');
      debugPrint('User email: ${userData['email']}');
      debugPrint('User first name: ${userData['first_name'] ?? userData['firstName']}');
      debugPrint('User last name: ${userData['last_name'] ?? userData['lastName']}');
      debugPrint('User role: ${userData['role']}');
      debugPrint('User is_active: ${userData['is_active'] ?? userData['isActive']}');
      debugPrint('User status: ${userData['status']}');
      debugPrint('User created_at: ${userData['created_at'] ?? userData['createdAt']}');
      debugPrint('User last_login: ${userData['last_login'] ?? userData['lastLoginAt']}');
      
      // Create a proper user object for the User.fromJson method
      // Handle both snake_case and camelCase fields from backend
      // Handle different field names from different backend endpoints
      
      // Convert backend role string to UserRole enum name format
      final backendRole = userData['role']?.toString() ?? '';
      String userRoleForParsing;
      
      switch (backendRole.toLowerCase()) {
        case 'clientreviewer':
        case 'client_reviewer':
          userRoleForParsing = 'clientReviewer';
          break;
        case 'deliverylead':
        case 'delivery_lead':
          userRoleForParsing = 'deliveryLead';
          break;
        case 'systemadmin':
        case 'system_admin':
          userRoleForParsing = 'systemAdmin';
          break;
        case 'teammember':
        case 'team_member':
        default:
          userRoleForParsing = 'teamMember';
          break;
      }
      
      final userJsonForParsing = {
        'id': userData['id'],
        'email': userData['email'],
        'name': userData['username'] ?? 
               '${userData['first_name'] ?? userData['firstName'] ?? ''} ${userData['last_name'] ?? userData['lastName'] ?? ''}'.trim(),
        'role': userRoleForParsing, // Use the converted role format
        'avatarUrl': userData['avatar_url'] ?? userData['avatarUrl'],
        'createdAt': userData['created_at'] ?? userData['createdAt'] ?? DateTime.now().toIso8601String(), // Provide default if missing
        'lastLoginAt': userData['last_login'] ?? userData['last_login_at'] ?? userData['lastLoginAt'],
        'isActive': userData['is_active'] ?? (userData['status'] == 'active') ?? userData['isActive'] ?? true,
        'projectIds': userData['project_ids'] ?? userData['projectIds'] ?? [],
        'preferences': userData['preferences'] ?? {},
        'emailVerified': userData['email_verified'] ?? userData['emailVerified'] ?? false,
        'emailVerifiedAt': userData['email_verified_at'] ?? userData['emailVerifiedAt'],
      };
      
      debugPrint('Final user JSON for parsing: $userJsonForParsing');
      
      return User.fromJson(userJsonForParsing);
    } catch (e) {
      debugPrint('Error parsing user: $e');
      return null;
    }
  }

  List<Deliverable> parseDeliverablesFromResponse(ApiResponse response) {
    if (!response.isSuccess || response.data == null) return [];
    
    try {
      final List<dynamic> items = response.data!['data'] ?? response.data!['deliverables'] ?? [];
      return items.map((item) => Deliverable.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error parsing deliverables: $e');
      return [];
    }
  }

  List<SprintMetrics> parseSprintMetricsFromResponse(ApiResponse response) {
    if (!response.isSuccess || response.data == null) return [];
    
    try {
      final List<dynamic> items = response.data!['data'] ?? response.data!['metrics'] ?? [];
      return items.map((item) => SprintMetrics.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error parsing sprint metrics: $e');
      return [];
    }
  }

  List<SignOffReport> parseSignOffReportsFromResponse(ApiResponse response) {
    if (!response.isSuccess || response.data == null) return [];
    
    try {
      final List<dynamic> items = response.data!['data'] ?? response.data!['reports'] ?? [];
      return items.map((item) => SignOffReport.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error parsing sign-off reports: \$e');
      return [];
    }
  }

  // Mock audit logs for development
  Map<String, dynamic> _getMockAuditLogs(int skip, int limit, String? action, String? userId) {
    final mockLogs = [
      {
        'id': '1',
        'action': 'user_login',
        'entity_type': 'user',
        'entity_id': 'user_123',
        'entity_name': 'John Doe',
        'user_id': 'user_123',
        'user_email': 'john.doe@example.com',
        'user_role': 'systemAdmin',
        'details': 'User logged in successfully',
        'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String(),
      },
      {
        'id': '2',
        'action': 'deliverable_submit',
        'entity_type': 'deliverable',
        'entity_id': 'del_456',
        'entity_name': 'API Documentation',
        'user_id': 'user_456',
        'user_email': 'jane.smith@example.com',
        'user_role': 'teamMember',
        'details': 'Deliverable submitted for review',
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': '3',
        'action': 'deliverable_approve',
        'entity_type': 'deliverable',
        'entity_id': 'del_789',
        'entity_name': 'UI Design Mockups',
        'user_id': 'user_789',
        'user_email': 'mike.jones@example.com',
        'user_role': 'deliveryLead',
        'details': 'Deliverable approved by delivery lead',
        'created_at': DateTime.now().subtract(const Duration(hours: 3)).toIso8601String(),
      },
      {
        'id': '4',
        'action': 'user_create',
        'entity_type': 'user',
        'entity_id': 'user_999',
        'entity_name': 'New User',
        'user_id': 'user_123',
        'user_email': 'john.doe@example.com',
        'user_role': 'systemAdmin',
        'details': 'Created new user account',
        'created_at': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
      },
      {
        'id': '5',
        'action': 'user_update',
        'entity_type': 'user',
        'entity_id': 'user_456',
        'entity_name': 'Jane Smith',
        'user_id': 'user_123',
        'user_email': 'john.doe@example.com',
        'user_role': 'systemAdmin',
        'details': 'Updated user permissions',
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      },
    ];

    // Apply action filter if specified
    List<Map<String, dynamic>> filteredLogs = List<Map<String, dynamic>>.from(mockLogs);
    if (action != null && action.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) => log['action'] == action).toList();
    }

    // Apply user filter if specified
    if (userId != null && userId.isNotEmpty) {
      filteredLogs = filteredLogs.where((log) => log['user_id'] == userId).toList();
    }

    // Apply pagination
    final startIndex = skip;
    final endIndex = startIndex + limit;
    final paginatedLogs = filteredLogs.sublist(
      startIndex.clamp(0, filteredLogs.length),
      endIndex.clamp(0, filteredLogs.length),
    );

    return {
      'audit_logs': paginatedLogs,
      'total': filteredLogs.length,
      'skip': skip,
      'limit': limit,
      'has_more': endIndex < filteredLogs.length,
    };
  }
}
