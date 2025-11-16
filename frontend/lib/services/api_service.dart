// ignore_for_file: unused_element, body_might_complete_normally_nullable, unused_field, require_trailing_commas, dead_code, prefer_interpolation_to_compose_strings, unnecessary_import

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../models/deliverable.dart';
import '../models/sprint.dart';
import '../models/audit_log.dart';
import '../models/notification.dart' as model;
import 'package:dio/dio.dart';

class ApiService {
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: Environment.apiBaseUrl,
    connectTimeout: const Duration(milliseconds: 5000),
    receiveTimeout: const Duration(milliseconds: 3000),
  ));
  static String? _accessToken;
  // Base URL for the backend API
  
  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  
  // Current tokens
  static String? _userId;
  
  // Initialize the service
  static Future<void> initialize() async {
    debugPrint('API Service initialized');
    // Load tokens from storage on initialization
    await _loadTokens();
  }
  
  // Load tokens from shared preferences
  static Future<void> _loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    _accessToken = prefs.getString(_accessTokenKey);
    _userId = prefs.getString(_userIdKey);
  }
  
  // Save tokens to shared preferences
  static Future<void> _saveTokens(String accessToken, String refreshToken, String userId, {String? firstName, String? lastName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    await prefs.setString(_userIdKey, userId);
    
    // Save user profile data if provided
    if (firstName != null) {
      await prefs.setString(_userFirstNameKey, firstName);
    }
    if (lastName != null) {
      await prefs.setString(_userLastNameKey, lastName);
    }
    
    _accessToken = accessToken;

    _userId = userId;
  }
  
  // Clear tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);

    await prefs.remove(_userIdKey);
    await prefs.remove(_userFirstNameKey);
    await prefs.remove(_userLastNameKey);
    
    _accessToken = null;

    _userId = null;
  }
  
  // Get current access token
  static String? get accessToken => _accessToken;
  
  // Get current user ID
  static String? get userId => _userId;
  
  // Get current user first name
  static Future<String?> get currentUserFirstName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userFirstNameKey);
  }
  
  // Get current user last name
  static Future<String?> get currentUserLastName async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userLastNameKey);
  }
  
  // Get current user full name
  static Future<String?> get currentUserFullName async {
    final firstName = await currentUserFirstName;
    final lastName = await currentUserLastName;
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    }
    return firstName ?? lastName;
  }
  
  // Get current user email
  static Future<String?> get currentUserEmail async {
    // Decode the JWT access token to extract the email claim
    if (_accessToken == null) return null;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> claims = jsonDecode(payload);
      return claims['email'] as String?;
    } catch (_) {
      return null;
    }
  }
  
  // Check if user is authenticated
  static bool get isAuthenticated => _accessToken != null;

  static String? get currentUserId => _userId;
  
  // Helper method to get headers with authorization
  static Map<String, String> _getHeaders() {
    final headers = {'Content-Type': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  // Public method to get authentication headers
  static Future<Map<String, String>?> getAuthHeaders() async {
    if (!isAuthenticated) {
      return null;
    }
    return _getHeaders();
  }
  
  // Helper method to extract a list from response data
  static List<dynamic>? _extractListFromResponse(
      dynamic data, List<String> possibleKeys,) {
    if (data is! Map<String, dynamic>) {
      return null;
    }
    
    for (final key in possibleKeys) {
      if (data.containsKey(key) && data[key] is List) {
        return data[key] as List<dynamic>;
      }
    }
    return null;
  }
  
  // Health checks
  static Future<bool> health() async {
    try {
      final response = await http.get(Uri.parse('${Environment.apiBaseUrl}/health'));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: \$e');
      return false;
    }
  }

  static Future<bool> root() async {
    try {
      final response = await http.get(Uri.parse(Environment.apiBaseUrl));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Root check failed: \$e');
      return false;
    }
  }

  static Future<bool> resendVerificationEmail(String email) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/auth/resend-verification'),
        headers: _getHeaders(),
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          final success = data['success'];
          if (success is bool) return success;
        }
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Resend verification email failed: \$e');
      return false;
    }
  }

  static Future<bool> checkEmailVerificationStatus(String email) async {
    try {
      final uri = Uri.parse('${Environment.apiBaseUrl}/auth/verification-status')
          .replace(queryParameters: {'email': email});
      final response = await http.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map<String, dynamic>) {
          if (data['verified'] == true) return true;
          if (data['isVerified'] == true) return true;
          final nested = data['data'];
          if (nested is Map<String, dynamic>) {
            if (nested['verified'] == true || nested['isVerified'] == true) return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('Check verification status failed: \$e');
      return false;
    }
  }

  // Approval endpoints
  static Future<List<Map<String, dynamic>>> getApprovalRequests({String? status, String? type, int? limit, int? offset}) async {
    try {
      final uri = Uri.parse('${Environment.apiBaseUrl}/approvals').replace(queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
        if (type != null && type.isNotEmpty) 'type': type,
        if (limit != null) 'limit': limit.toString(),
        if (offset != null) 'offset': offset.toString(),
      });
      final response = await http.get(uri, headers: _getHeaders());
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = _extractListFromResponse(data, ['data', 'approvals', 'items']) ?? [];
        return list.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching approvals: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createApprovalRequest(Map<String, dynamic> requestData) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/approvals'),
        headers: _getHeaders(),
        body: jsonEncode(requestData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data is Map<String, dynamic> ? data : {'data': data};
      }
      return null;
    } catch (e) {
      debugPrint('Error creating approval request: $e');
      return null;
    }
  }

  static Future<bool> approveApprovalRequest(String id, {String? comment}) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/approvals/$id/approve'),
        headers: _getHeaders(),
        body: comment != null && comment.isNotEmpty ? jsonEncode({'comment': comment}) : null,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error approving request: $e');
      return false;
    }
  }

  static Future<bool> rejectApprovalRequest(String id, {String? comment}) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/approvals/$id/reject'),
        headers: _getHeaders(),
        body: comment != null && comment.isNotEmpty ? jsonEncode({'comment': comment}) : null,
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error rejecting request: $e');
      return false;
    }
  }

  static Future<bool> sendApprovalReminder(String id) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/approvals/$id/reminder'),
        headers: _getHeaders(),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error sending reminder: $e');
      return false;
    }
  }
  // Authentication methods
  static Future<TokenResponse> signUp(UserCreate userData) async {
    final requestBody = jsonEncode(userData.toJson());
    debugPrint('Registration request body: ' + requestBody);
    
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    
    debugPrint('Registration response status: ' + response.statusCode.toString());
    debugPrint('Registration response body: ' + response.body);
    
    final responseData = jsonDecode(response.body);
    final tokenResponse = TokenResponse.fromJson(responseData);
    
    // Save tokens after successful signup
    await _saveTokens(
      tokenResponse.accessToken,
      tokenResponse.refreshToken,
      tokenResponse.user.id.toString(),
    );
    
    // Note: User provider updates are now handled by ApiAuthNotifier
    // This method should only handle token storage and API calls

    return tokenResponse;
  }

  static Future<TokenResponse> login(String email, String password) async {
    final requestBody = jsonEncode({
      'email': email,
      'password': password,
    });
    
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    );
    
    debugPrint('Login response status: ' + response.statusCode.toString());
    debugPrint('Login response body: ' + response.body);
    
    final responseData = jsonDecode(response.body);
    final tokenResponse = TokenResponse.fromJson(responseData);
    
    // Save tokens after successful login
    await _saveTokens(
      tokenResponse.accessToken,
      tokenResponse.refreshToken,
      tokenResponse.user.id.toString(),
      firstName: tokenResponse.user.firstName,
      lastName: tokenResponse.user.lastName,
    );
    
    // Note: User provider updates are now handled by ApiAuthNotifier
    // This method should only handle token storage and API calls
    
    return tokenResponse;
  }

  // Alias for login method
  static Future<TokenResponse> signIn(String email, String password) async {
    return login(email, password);
  }

  // Fetch user profile
  static Future<User> fetchUserProfile() async {
    if (!isAuthenticated) {
      throw Exception('User not authenticated');
    }
    
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/users/me'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData);
      } else {
        throw Exception('Failed to fetch user profile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Failed to fetch user profile: $e');
      
      // Fallback: create user from token claims if API call fails
      final userEmail = await currentUserEmail;
      final firstName = await currentUserFirstName;
      final lastName = await currentUserLastName;
      
      return User(
        id: userId ?? '0',
        email: userEmail ?? 'unknown@user.com',
        firstName: firstName ?? 'User',
        lastName: lastName ?? 'Unknown',
        company: 'Unknown',
        role: UserRole.teamMember,
        isActive: true,
        isVerified: true,
        createdAt: DateTime.now(),
      );
    }
  }
  
  // Deliverable methods
  static Future<List<Deliverable>> getDeliverables({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/deliverables?skip=\$skip&limit=\$limit'),
      headers: _getHeaders(),
    );
    
    final dynamic responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData is List
        ? responseData
        : (responseData['data'] ?? responseData['items'] ?? responseData['deliverables'] ?? []);
    return data.map((json) => Deliverable.fromJson(json)).toList();
  }
  
  static Future<Deliverable> createDeliverable(DeliverableCreate deliverable) async {
    final payload = {
      'title': deliverable.title,
      'description': deliverable.description,
      'due_date': deliverable.dueDate.toIso8601String(),
      'definition_of_done': deliverable.definitionOfDone.join('\n'),
      'evidence_links': deliverable.evidenceLinks,
      'sprintIds': deliverable.sprintIds,
      'status': 'draft',
    };
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/deliverables'),
      headers: _getHeaders(),
      body: jsonEncode(payload),
    );
    
    final dynamic responseData = jsonDecode(response.body);
    final dynamic item = responseData is Map ? (responseData['data'] ?? responseData['deliverable'] ?? responseData) : responseData;
    return Deliverable.fromJson(item);
  }
  
  static Future<Deliverable> updateDeliverable(int id, DeliverableUpdate deliverable) async {
    final response = await http.put(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/\$id'),
      headers: _getHeaders(),
      body: jsonEncode(deliverable.toJson()),
    );
    
    final responseData = jsonDecode(response.body);
    return Deliverable.fromJson(responseData);
  }
  
  static Future<void> deleteDeliverable(int id) async {
    await http.delete(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/\$id'),
      headers: _getHeaders(),
    );
  }
  
  static Future<List<Deliverable>> getDeliverablesBySprint(int sprintId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/sprint/\$sprintId'),
      headers: _getHeaders(),
    );
    
    final dynamic responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData is List
        ? responseData
        : (responseData['data'] ?? responseData['items'] ?? responseData['deliverables'] ?? []);
    return data.map((json) => Deliverable.fromJson(json)).toList();
  }
  
  static Future<List<Sprint>> getSprintsForDeliverable(int deliverableId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/\$deliverableId/sprints'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] as List<dynamic>;
    return data.map((json) => Sprint.fromJson(json)).toList();
  }
  
  static Future<void> addDeliverableToSprint(int deliverableId, int sprintId) async {
    await http.post(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/\$deliverableId/sprints/\$sprintId'),
      headers: _getHeaders(),
    );
  }
  
  static Future<void> removeDeliverableFromSprint(int deliverableId, int sprintId) async {
    await http.delete(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/\$deliverableId/sprints/\$sprintId'),
      headers: _getHeaders(),
    );
  }
  
  static Future<List<Sprint>> getAvailableSprintsForDeliverable(int deliverableId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/deliverables/\$deliverableId/available-sprints'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] as List<dynamic>;
    return data.map((json) => Sprint.fromJson(json)).toList();
  }
  
  // Sprint methods
  static Future<List<Sprint>> getSprints({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/sprints?skip=$skip&limit=$limit'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] as List<dynamic>;
    return data.map((json) => Sprint.fromJson(json)).toList();
  }
  
  static Future<Sprint> createSprint(SprintCreate sprint) async {
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/sprints'),
      headers: _getHeaders(),
      body: jsonEncode(sprint.toJson()),
    );
    
    final responseData = jsonDecode(response.body);
    return Sprint.fromJson(responseData);
  }
  
  static Future<Sprint> updateSprint(int id, SprintUpdate sprint) async {
    final response = await http.put(
      Uri.parse('${Environment.apiBaseUrl}/sprints/$id'),
      headers: _getHeaders(),
      body: jsonEncode(sprint.toJson()),
    );
    
    final responseData = jsonDecode(response.body);
    return Sprint.fromJson(responseData);
  }
  
  static Future<void> deleteSprint(int id) async {
    await http.delete(
      Uri.parse('${Environment.apiBaseUrl}/sprints/$id'),
      headers: _getHeaders(),
    );
  }
  
  // Signoff methods
  static Future<List<Map<String, dynamic>>> getSignoffsBySprint(int sprintId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/signoff/sprint/$sprintId'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] as List<dynamic>;
    return data.map((json) => json as Map<String, dynamic>).toList();
  }
  
  static Future<Map<String, dynamic>> approveSignoff(int signoffId, bool approved, String? comments) async {
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/signoff/$signoffId/approve'),
      headers: _getHeaders(),
      body: jsonEncode({
        'approved': approved,
        'comments': comments,
      }),
    );
    
    final responseData = jsonDecode(response.body);
    return responseData as Map<String, dynamic>;
  }
  
  static Future<String> generateReleaseReadinessPDF(int sprintId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/sprints/$sprintId/release-readiness/pdf'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    return responseData['pdf_url'] as String;
  }
  
  // Audit log methods
  static Future<List<AuditLog>> getAuditLogs({int skip = 0, int limit = 100}) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/audit?skip=$skip&limit=$limit'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] as List<dynamic>;
    return data.map((json) => AuditLog.fromJson(json)).toList();
  }
  
  static Future<List<AuditLog>> getAuditLogsForEntity(String entityType, int entityId) async {
    final response = await http.get(
      Uri.parse('${Environment.apiBaseUrl}/audit/entity/$entityType/$entityId'),
      headers: _getHeaders(),
    );
    
    final responseData = jsonDecode(response.body);
    final List<dynamic> data = responseData['data'] as List<dynamic>;
    return data.map((json) => AuditLog.fromJson(json)).toList();
  }
  
  static Future<AuditLog> createAuditLog(AuditLogCreate auditLog) async {
    final response = await http.post(
      Uri.parse('${Environment.apiBaseUrl}/audit'),
      headers: _getHeaders(),
      body: jsonEncode(auditLog.toJson()),
    );
    
    final responseData = jsonDecode(response.body);
    return AuditLog.fromJson(responseData);
  }
  
  // Dashboard methods
  static Future<Map<String, dynamic>> getDashboardData() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/analytics/dashboard'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load dashboard data: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load dashboard data: $e');
    }
  }

  static Future<String?> getCurrentUserEmail() async {
    return await currentUserEmail;
  }

  static String? getCurrentUserRole() {
    // Extract role from JWT token
    if (_accessToken == null) return null;
    try {
      final parts = _accessToken!.split('.');
      if (parts.length != 3) return null;
      final payload = utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final Map<String, dynamic> claims = jsonDecode(payload);
      return claims['role'] as String?;
    } catch (_) {
      return null;
    }
  }

  static Future<List<User>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/users'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> data = responseData['data'] as List<dynamic>;
        return data.map((userJson) => User.fromJson(userJson)).toList();
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load users: $e');
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/users/$userId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }

  static Future<User> createUser(String username, String email, String password, String role) async {
    try {
      final response = await http.post(
        Uri.parse('${Environment.apiBaseUrl}/users'),
        headers: _getHeaders(),
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
          'role': role,
        }),
      );
      
      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return User.fromJson(responseData);
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Notification methods
  static Future<List<model.Notification>> getNotifications({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('${Environment.apiBaseUrl}/notifications/me?skip=$skip&limit=$limit'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => model.Notification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load notifications: $e');
    }
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final response = await http.put(
        Uri.parse('${Environment.apiBaseUrl}/notifications/$notificationId/read'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to mark notification as read: $e');
    }
  }

  static Future<void> markAllNotificationsAsRead() async {
    try {
      // This endpoint might need to be implemented in the backend
      // For now, we'll mark each notification individually
      final notifications = await getNotifications();
      for (final notification in notifications) {
        if (!notification.isRead) {
          await markNotificationAsRead(notification.id);
        }
      }
    } catch (e) {
      throw Exception('Failed to mark all notifications as read: $e');
    }
  }

  static Future<void> deleteNotification(String notificationId) async {
    try {
      final response = await http.delete(
        Uri.parse('${Environment.apiBaseUrl}/notifications/$notificationId'),
        headers: _getHeaders(),
      );
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete notification: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to delete notification: $e');
    }
  }
}
class ApiException implements Exception {
  final String message;

  const ApiException(this.message);

  @override
  String toString() => message;
}