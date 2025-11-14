import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'package:khono/models/user.dart';
import 'package:khono/models/user_role.dart';
import 'package:khono/models/deliverable.dart';
import 'package:khono/models/sprint_metrics.dart';
import 'package:khono/models/sign_off_report.dart';

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
    return await _apiClient.register(email, password, name, role.index.toString());
  }

  Future<ApiResponse> signOut() async {
    return await _apiClient.logout();
  }

  Future<ApiResponse> getCurrentUser() async {
    return await _apiClient.getCurrentUser();
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> updates) async {
    final me = await _apiClient.getCurrentUser();
    if (!me.isSuccess || me.data == null) {
      return ApiResponse.error('Failed to load current user');
    }
    final user = me.data['user'] ?? me.data;
    final id = user['id']?.toString();
    if (id == null || id.isEmpty) {
      return ApiResponse.error('Missing user id');
    }
    return await _apiClient.put('/profile/$id', body: updates);
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

  // Admin-only user creation endpoint
  Future<ApiResponse> createUser({
    required String email,
    required String name,
    required String role,
    required String password,
  }) async {
    return await _apiClient.post('/users', body: {
      'email': email,
      'name': name,
      'role': role,
      'password': password,
    },);
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

  Future<ApiResponse> deleteSignOffReport(String reportId) async {
    return await _apiClient.delete('/sign-off-reports/$reportId');
  }

  Future<ApiResponse> submitSignOffReport(String reportId) async {
    return await _apiClient.post('/sign-off-reports/$reportId/submit');
  }

  Future<ApiResponse> approveSignOffReport(String reportId, String? comment) async {
    return await _apiClient.post('/sign-off-reports/$reportId/approve', body: {
      'comment': comment,
    },);
  }

  Future<ApiResponse> requestChangesSignOffReport(String reportId, String changeRequest) async {
    return await _apiClient.post('/sign-off-reports/$reportId/request-changes', body: {
      'change_request': changeRequest,
    },);
  }

  // Project endpoints
  Future<ApiResponse> getProjects({int page = 1, int limit = 20, String? search}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (search != null && search.isNotEmpty) {
      queryParams['search'] = search;
    }
    return await _apiClient.get('/projects', queryParams: queryParams);
  }

  Future<ApiResponse> getProject(String projectId) async {
    return await _apiClient.get('/projects/$projectId');
  }

  Future<ApiResponse> createProject(Map<String, dynamic> projectData) async {
    return await _apiClient.post('/projects', body: projectData);
  }

  Future<ApiResponse> updateProject(String projectId, Map<String, dynamic> updates) async {
    return await _apiClient.put('/projects/$projectId', body: updates);
  }

  Future<ApiResponse> deleteProject(String projectId) async {
    return await _apiClient.delete('/projects/$projectId');
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
    return await _apiClient.get('/analytics/dashboard');
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
    
    final response = await _apiClient.get('/audit-logs', queryParams: queryParams);
    
    // If the endpoint doesn't exist or returns error, provide empty response
    if (!response.isSuccess) {
      debugPrint('Audit endpoint not available, returning empty response');
      return ApiResponse.success({
        'audit_logs': [],
        'items': [],
        'logs': [],
        'total': 0,
        'total_count': 0,
        'skip': skip,
        'limit': limit,
        'has_more': false,
      }, 200,);
    }
    
    return response;
  }

  // File upload endpoints
  Future<ApiResponse> uploadFile(String filePath, String fileName, String fileType) async {
    return await _apiClient.uploadFile('/files/upload', filePath, fileName, fileType);
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
    return await _apiClient.post('/system/cache/clear');
  }

  Future<ApiResponse> optimizeDatabase() async {
    return await _apiClient.post('/system/optimize-database');
  }

  Future<ApiResponse> runDiagnostics() async {
    return await _apiClient.get('/system/diagnostics');
  }

  // System statistics endpoint
  Future<ApiResponse> getSystemStats() async {
    return await _apiClient.get('/system/stats');
  }

  // System maintenance endpoints
  Future<ApiResponse> toggleMaintenanceMode(bool enabled, {String? message}) async {
    return await _apiClient.post('/system/maintenance', body: {
      'enabled': enabled,
      'message': message,
    },);
  }

  // System backup management
  Future<ApiResponse> listBackups() async {
    return await _apiClient.get('/system/backups');
  }

  // Audit logs endpoint (real implementation)
  Future<ApiResponse> getRealAuditLogs({int skip = 0, int limit = 100, String? action, String? userId}) async {
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
    
    return await _apiClient.get('/audit-logs', queryParams: queryParams);
  }

  // User settings endpoints
  Future<ApiResponse> getUserSettings() async {
    return await _apiClient.get('/settings/me');
  }

  Future<ApiResponse> updateUserSettings(Map<String, dynamic> settings) async {
    return await _apiClient.put('/settings/me', body: settings);
  }

  Future<ApiResponse> resetUserSettings() async {
    return await _apiClient.delete('/settings/me');
  }

  Future<ApiResponse> exportUserData() async {
    return await _apiClient.get('/user/data/export');
  }

  Future<ApiResponse> clearUserCache() async {
    return await _apiClient.delete('/user/cache');
  }

  // Sprint tickets endpoints
  Future<ApiResponse> getSprintTickets(String sprintId) async {
    return await _apiClient.get('/sprints/$sprintId/tickets');
  }

  // File listing endpoint
  Future<ApiResponse> listFiles({String? prefix}) async {
    final queryParams = prefix != null ? {'prefix': prefix} : null;
    return await _apiClient.get('/files', queryParams: queryParams);
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

  // Approval requests endpoints
  Future<ApiResponse> getApprovalRequests({String? status, String? deliverableId, String? requestedBy, int page = 1, int limit = 100}) async {
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };
    if (status != null) queryParams['status'] = status;
    if (deliverableId != null) queryParams['deliverable_id'] = deliverableId;
    if (requestedBy != null) queryParams['requested_by'] = requestedBy;
    
    return await _apiClient.get('/approvals', queryParams: queryParams);
  }

  Future<ApiResponse> getApprovalRequest(String id) async {
    return await _apiClient.get('/approvals/$id');
  }


  Future<ApiResponse> approveRequest(String id, Map<String, dynamic> approvalData) async {
    return await _apiClient.put('/approvals/$id/approve', body: approvalData);
  }

  Future<ApiResponse> rejectRequest(String id, Map<String, dynamic> rejectionData) async {
    return await _apiClient.put('/approvals/$id/reject', body: rejectionData);
  }

  Future<ApiResponse> sendReminder(String id) async {
    return await _apiClient.put('/approvals/$id/remind');
  }

  Future<ApiResponse> getApprovalMetrics() async {
    return await _apiClient.get('/approvals/stats/metrics');
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
      debugPrint('User first name: ${userData['first_name'] ?? userData['firstName'] ?? userData['firstname']}');
      debugPrint('User last name: ${userData['last_name'] ?? userData['lastName'] ?? userData['lastname']}');
      debugPrint('User role: ${userData['role']}');
      debugPrint('User is_active: ${userData['is_active'] ?? userData['isActive'] ?? userData['isactive']}');
      debugPrint('User status: ${userData['status']}');
      debugPrint('User created_at: ${userData['created_at'] ?? userData['createdAt'] ?? userData['createdat']}');
      debugPrint('User last_login: ${userData['last_login'] ?? userData['lastLoginAt'] ?? userData['lastlogin'] ?? userData['lastLogin']}');
      
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
        'id': userData['id']?.toString(),
        'email': userData['email'],
        'name': userData['name'] ?? userData['username'] ?? 
               '${userData['first_name'] ?? userData['firstName'] ?? userData['firstname'] ?? ''} ${userData['last_name'] ?? userData['lastName'] ?? userData['lastname'] ?? ''}'.trim(),
        'role': userRoleForParsing, // Use the converted role format
        'avatarUrl': userData['avatar_url'] ?? userData['avatarUrl'] ?? userData['avatarurl'],
        'createdAt': userData['created_at'] ?? userData['createdAt'] ?? userData['createdat'] ?? DateTime.now().toIso8601String(), // Provide default if missing
        'lastLoginAt': userData['last_login'] ?? userData['last_login_at'] ?? userData['lastLoginAt'] ?? userData['lastlogin'] ?? userData['lastLogin'],
        'isActive': userData['is_active'] ?? userData['isActive'] ?? userData['isactive'] ?? (userData['status'] == 'active') ?? true,
        'projectIds': userData['project_ids'] ?? userData['projectIds'] ?? userData['projectids'] ?? [],
        'preferences': userData['preferences'] ?? {},
        'emailVerified': userData['email_verified'] ?? userData['emailVerified'] ?? userData['emailverified'] ?? false,
        'emailVerifiedAt': userData['email_verified_at'] ?? userData['emailVerifiedAt'] ?? userData['emailverifiedat'],
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
      final dynamic raw = response.data;
      final List<dynamic> items = raw is List ? raw : (raw['data'] ?? raw['reports'] ?? raw['items'] ?? []);
      return items.map((item) => SignOffReport.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Error parsing sign-off reports: $e');
      return [];
    }
  }

  // QA-specific endpoints
  Future<ApiResponse> getTestQueue() async {
    return await _apiClient.get('/qa/test-queue');
  }

  Future<ApiResponse> getQualityMetrics() async {
    return await _apiClient.get('/qa/quality-metrics');
  }

  Future<ApiResponse> getBugReports({int limit = 10}) async {
    final queryParams = {'limit': limit.toString()};
    return await _apiClient.get('/qa/bug-reports', queryParams: queryParams);
  }

  Future<ApiResponse> getTestCoverage() async {
    return await _apiClient.get('/qa/test-coverage');
  }

  // Approval endpoints


  Future<ApiResponse> createApprovalRequest(Map<String, dynamic> requestData) async {
    return await _apiClient.post('/approvals', body: requestData);
  }




}
