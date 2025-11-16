// ignore_for_file: unused_element, body_might_complete_normally_nullable, unused_field, require_trailing_commas, dead_code, prefer_interpolation_to_compose_strings, unnecessary_import

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../utils/error_handler.dart';
import '../utils/retry_interceptor.dart';
import '../utils/type_converters.dart';
import '../models/user.dart';

class ApiService {
  // Base URL for the backend API
  static String baseUrl = Environment.apiBaseUrl;
  
  // Retry options for network requests
  static const RetryOptions _retryOptions = RetryOptions(
    maxRetries: 3,
    maxDelay: Duration(seconds: 10),
    retryOnNetworkErrors: true,
    retryOnServerErrors: true,
    retryOnClientErrors: false,
  );
  
  // Token storage keys
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userIdKey = 'user_id';
  static const String _userFirstNameKey = 'user_first_name';
  static const String _userLastNameKey = 'user_last_name';
  
  // Current tokens
  static String? _accessToken;
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
  
  // Helper method for making HTTP requests with error handling
  static Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn, {
    bool retry = true,
    void Function(AppError error, int attempt, Duration delay)? onRetry,
  }) async {
    try {
      if (retry) {
        return await RetryInterceptor.executeWithRetry(
          requestFn,
          _retryOptions,
          onRetry: onRetry,
        );
      } else {
        return await requestFn();
      }
    } catch (error) {
      if (error is AppError) {
        rethrow;
      }
      throw ErrorHandler.handleException(error);
    }
  }
  
  // Helper method to handle JSON response parsing
  static dynamic _parseResponse(http.Response response) {
    if (response.statusCode >= 400) {
      throw ErrorHandler.handleHttpError(response);
    }
    
    if (response.body.isEmpty) {
      return null;
    }
    
    try {
      return jsonDecode(response.body);
    } catch (e) {
      throw AppError.unknown(
        'Failed to parse response: \${e.toString()}',
        originalError: e,
      );
    }
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
      final response = await _makeRequest(() => http.get(Uri.parse('$baseUrl/health')));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Health check failed: \$e');
      return false;
    }
  }

  static Future<bool> root() async {
    try {
      final response = await _makeRequest(() => http.get(Uri.parse(baseUrl)));
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Root check failed: \$e');
      return false;
    }
  }
  
  // Authentication methods
  static Future<TokenResponse> signUp(UserCreate userData) async {
    final requestBody = jsonEncode(userData.toJson());
    debugPrint('Registration request body: ' + requestBody);
    
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: requestBody,
    ));
    
    debugPrint('Registration response status: ' + response.statusCode.toString());
    debugPrint('Registration response body: ' + response.body);
    
    final responseData = await _parseResponse(response);
    final tokenResponse = TokenResponse.fromJson(responseData);
    
    // Save tokens after successful signup
    await _saveTokens(
      tokenResponse.accessToken,
      tokenResponse.refreshToken,
      tokenResponse.user.id.toString(),
    );
    
    return tokenResponse;
  }

  static Future<TokenResponse> signIn(String email, String password) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    ));
    
    final responseData = await _parseResponse(response);
    
    // Extract user ID from the access token (JWT)
    final accessToken = responseData?['token']?.toString();
    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('Access token not found in response');
    }
    final tokenParts = accessToken.split('.');
    if (tokenParts.length != 3) {
      throw Exception('Invalid access token format');
    }
    
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1])));
    final Map<String, dynamic> claims = jsonDecode(payload);
    
    // Safe extraction of claims with null checks
    final userId = claims['id']?.toString() ?? claims['sub']?.toString() ?? '';
    final userRole = claims['role']?.toString() ?? 'user';
    
    // Parse user ID with proper error handling
    int parsedUserId;
    try {
      parsedUserId = int.parse(userId);
    } catch (e) {
      throw Exception('Invalid user ID format in token: $userId');
    }
    
    // Create a token response that matches the backend structure
    final tokenResponse = TokenResponse(
      accessToken: accessToken,
      tokenType: 'bearer',
      refreshToken: responseData?['refresh_token']?.toString() ?? '',
      expiresIn: 3600, // Default expiration
      user: User.fromJson({
        'id': parsedUserId,
        'email': email,
        'first_name': responseData?['user']?['first_name']?.toString() ?? 'Unknown',
        'last_name': responseData?['user']?['last_name']?.toString() ?? 'User',
        'role': userRole,
        'is_active': true,
        'is_verified': true,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
    
    // Save tokens after successful signin
    await _saveTokens(
      tokenResponse.accessToken,
      tokenResponse.refreshToken,
      tokenResponse.user.id.toString(),
      firstName: tokenResponse.user.firstName,
      lastName: tokenResponse.user.lastName,
    );
    
    return tokenResponse;
  }
  
  // Deliverables
  static Future<List<Map<String, dynamic>>> getDeliverables({int skip = 0, int limit = 100}) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/deliverables?skip=$skip&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return List<Map<String, dynamic>>.from(data ?? []);
  }
  
  static Future<Map<String, dynamic>> createDeliverable({
    required String title,
    String? description,
    String? definitionOfDone,
    String status = 'pending',
    String? assignedTo,
    String? createdBy, 
    required String priority, 
    DateTime? dueDate, 
    required List<String> evidenceLinks, 
    required List<String> contributingSprints,
    String? demoLink,
    String? repoLink,
    String? testSummaryLink,
    String? userGuideLink,
    int? testPassRate,
    int? codeCoverage,
    int? escapedDefects,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/deliverables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'definition_of_done': definitionOfDone,
        'status': status,
        'assigned_to': assignedTo,
        'created_by': createdBy,
        'priority': priority,
        'due_date': dueDate?.toIso8601String(),
        'evidence_links': evidenceLinks,
        'contributing_sprints': contributingSprints,
        'demo_link': demoLink,
        'repo_link': repoLink,
        'test_summary_link': testSummaryLink,
        'user_guide_link': userGuideLink,
        'test_pass_rate': testPassRate,
        'code_coverage': codeCoverage,
        'escaped_defects': escapedDefects,
      }),
    ));
    
    return _parseResponse(response);
  }
  
  static Future<Map<String, dynamic>> updateDeliverable({
    required int id,
    String? title,
    String? description,
    String? status,
    int? sprintId,
  }) async {
    final response = await _makeRequest(() => http.put(
      Uri.parse('$baseUrl/deliverables/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'status': status,
        'sprint_id': sprintId,
      }),
    ));
    
    return _parseResponse(response);
  }
  
  static Future<bool> deleteDeliverable(int id) async {
    final response = await _makeRequest(() => http.delete(
      Uri.parse('$baseUrl/deliverables/$id'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    return response.statusCode == 204;
  }

  static Future<List<Map<String, dynamic>>> getDeliverablesBySprint(int sprintId) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/deliverables/sprint/$sprintId'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return List<Map<String, dynamic>>.from(data ?? []);
  }

  // Deliverable-Sprint Association Methods
  static Future<List<Map<String, dynamic>>> getSprintsForDeliverable(int deliverableId) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/deliverables/$deliverableId/sprints'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return List<Map<String, dynamic>>.from(data ?? []);
  }

  static Future<bool> addDeliverableToSprint(int deliverableId, int sprintId) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/deliverables/$deliverableId/sprints/$sprintId'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    return response.statusCode == 200;
  }

  static Future<bool> removeDeliverableFromSprint(int deliverableId, int sprintId) async {
    final response = await _makeRequest(() => http.delete(
      Uri.parse('$baseUrl/deliverables/$deliverableId/sprints/$sprintId'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getAvailableSprintsForDeliverable(int deliverableId) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/deliverables/$deliverableId/available-sprints'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return List<Map<String, dynamic>>.from(data ?? []);
  }
  
  // Sprints
  static Future<List<Map<String, dynamic>>> getSprints({int skip = 0, int limit = 100}) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/sprints?skip=$skip&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return List<Map<String, dynamic>>.from(data ?? []);
  }
  
  static Future<Map<String, dynamic>> createSprint({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String status = 'planning',
    int? plannedPoints,
    int? committedPoints,
    int? completedPoints,
    int? carriedOverPoints,
    int? addedDuringSprint,
    int? removedDuringSprint,
    int? testPassRate,
    int? codeCoverage,
    int? escapedDefects,
    int? defectsOpened,
    int? defectsClosed,
    String? defectSeverityMix,
    int? codeReviewCompletion,
    String? documentationStatus,
    String? uatNotes,
    int? uatPassRate,
    int? risksIdentified,
    int? risksMitigated,
    String? blockers,
    String? decisions,
    String? createdBy,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/sprints'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
        'planned_points': plannedPoints,
        'committed_points': committedPoints,
        'completed_points': completedPoints,
        'carried_over_points': carriedOverPoints,
        'added_during_sprint': addedDuringSprint,
        'removed_during_sprint': removedDuringSprint,
        'test_pass_rate': testPassRate,
        'code_coverage': codeCoverage,
        'escaped_defects': escapedDefects,
        'defects_opened': defectsOpened,
        'defects_closed': defectsClosed,
        'defect_severity_mix': defectSeverityMix,
        'code_review_completion': codeReviewCompletion,
        'documentation_status': documentationStatus,
        'uat_notes': uatNotes,
        'uat_pass_rate': uatPassRate,
        'risks_identified': risksIdentified,
        'risks_mitigated': risksMitigated,
        'blockers': blockers,
        'decisions': decisions,
        'created_by': createdBy,
      }),
    ));
    
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>?> updateSprint({
    required int id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    int? plannedPoints,
    int? committedPoints,
    int? completedPoints,
    int? carriedOverPoints,
    int? addedDuringSprint,
    int? removedDuringSprint,
    int? testPassRate,
    int? codeCoverage,
    int? escapedDefects,
    int? defectsOpened,
    int? defectsClosed,
    String? defectSeverityMix,
    int? codeReviewCompletion,
    String? documentationStatus,
    String? uatNotes,
    int? uatPassRate,
    int? risksIdentified,
    int? risksMitigated,
    String? blockers,
    String? decisions,
  }) async {
    final response = await _makeRequest(() => http.put(
      Uri.parse('$baseUrl/sprints/$id'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
        'planned_points': plannedPoints,
        'committed_points': committedPoints,
        'completed_points': completedPoints,
        'carried_over_points': carriedOverPoints,
        'added_during_sprint': addedDuringSprint,
        'removed_during_sprint': removedDuringSprint,
        'test_pass_rate': testPassRate,
        'code_coverage': codeCoverage,
        'escaped_defects': escapedDefects,
        'defects_opened': defectsOpened,
        'defects_closed': defectsClosed,
        'defect_severity_mix': defectSeverityMix,
        'code_review_completion': codeReviewCompletion,
        'documentation_status': documentationStatus,
        'uat_notes': uatNotes,
        'uat_pass_rate': uatPassRate,
        'risks_identified': risksIdentified,
        'risks_mitigated': risksMitigated,
        'blockers': blockers,
        'decisions': decisions,
      }),
    ));

    return _parseResponse(response);
  }

  static Future<bool> updateSprintStatus(int sprintId, String status) async {
    final response = await _makeRequest(() => http.put(
      Uri.parse('$baseUrl/sprints/$sprintId'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    ));
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = _parseResponse(response);
      if (data is Map && data.containsKey('success')) {
        final success = data['success'];
        if (success is bool) return success;
      }
      return true;
    }
    return false;
  }

  static Future<bool> deleteSprint(int id) async {
    final response = await _makeRequest(() => http.delete(
      Uri.parse('$baseUrl/sprints/$id'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    return response.statusCode == 204;
  }

  // Signoff
  static Future<List<Map<String, dynamic>>> getSignoffsBySprint(int sprintId) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/signoff/sprint/$sprintId'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    // Handle different response formats
    try {
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      
      // Check common response structures
      final List<dynamic>? items = _extractListFromResponse(data, ['signoffs', 'items', 'data']);
      if (items != null) {
        return List<Map<String, dynamic>>.from(items);
      }
      
      debugPrint('Unexpected response format for signoffs: $data');
      return [];
    } catch (e) {
      debugPrint('Error parsing signoffs response: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createSignoff({
    required int sprintId,
    required String signerName,
    required String signerEmail,
    String? comments,
    bool isApproved = false,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/signoff'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sprint_id': sprintId,
        'signer_name': signerName,
        'signer_email': signerEmail,
        'comments': comments,
        'is_approved': isApproved,
      }),
    ));
    
    return _parseResponse(response);
  }

  static Future<Map<String, dynamic>?> approveSignoff(int signoffId) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/signoff/$signoffId/approve'),
      headers: {'Content-Type': 'application/json'},
    ));

    return _parseResponse(response);
  }

  // Release Readiness Gate - AI Analysis
  static Future<Map<String, dynamic>> analyzeReleaseReadiness(int sprintId) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/sprints/$sprintId/release-readiness'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return Map<String, dynamic>.from(data ?? {});
  }

  static Future<Map<String, dynamic>> getReleaseReadinessReport(int sprintId) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/sprints/$sprintId/release-readiness/report'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    final data = _parseResponse(response);
    return Map<String, dynamic>.from(data ?? {});
  }

  static Future<bool> generateReleaseReadinessPDF(int sprintId) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/sprints/$sprintId/release-readiness/pdf'),
      headers: {'Content-Type': 'application/json'},
    ));
    
    return response.statusCode == 200;
  }

  // Audit Logs
  static Future<List<Map<String, dynamic>>> getAuditLogs({int skip = 0, int limit = 100}) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/audit?skip=$skip&limit=$limit'),
      headers: {'Content-Type': 'application/json'},
    ));

    final data = _parseResponse(response);
    // Handle different response formats
    try {
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      
      // Check common response structures
      final List<dynamic>? items = _extractListFromResponse(data, ['audit_logs', 'items', 'data']);
      if (items != null) {
        return List<Map<String, dynamic>>.from(items);
      }
      
      // Handle Node.js backend response format
      if (data is Map<String, dynamic> && data.containsKey('success') && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      debugPrint('Unexpected response format for audit logs: \$data');
      return [];
    } catch (e) {
      debugPrint('Error parsing audit logs response: \$e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAuditLogsForEntity({
    required String entityType,
    required int entityId,
  }) async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/audit/entity/$entityType/$entityId'),
      headers: {'Content-Type': 'application/json'},
    ));

    final data = _parseResponse(response);
    // Handle different response formats
    try {
      if (data is List) {
        return data.cast<Map<String, dynamic>>();
      }
      
      // Check common response structures
      final List<dynamic>? items = _extractListFromResponse(data, ['audit_logs', 'items', 'data']);
      if (items != null) {
        return List<Map<String, dynamic>>.from(items);
      }
      
      // Handle Node.js backend response format
      if (data is Map<String, dynamic> && data.containsKey('success') && data['data'] is List) {
        return List<Map<String, dynamic>>.from(data['data']);
      }
      
      debugPrint('Unexpected response format for audit logs by entity: \$data');
      return [];
    } catch (e) {
      debugPrint('Error parsing audit logs by entity response: \$e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> createAuditLog({
    required String entityType,
    required int entityId,
    required String action,
    String? userEmail,
    String? userRole,
    String? sessionId,
    String? ipAddress,
    String? userAgent,
    String? actionCategory,
    String? entityName,
    Map<String, dynamic>? oldValues,
    Map<String, dynamic>? newValues,
    Map<String, dynamic>? changedFields,
    String? requestId,
    String? endpoint,
    String? httpMethod,
    int? statusCode, required String details,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/audit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'user_email': userEmail,
        'user_role': userRole,
        'session_id': sessionId,
        'ip_address': ipAddress,
        'user_agent': userAgent,
        'action_category': actionCategory,
        'entity_name': entityName,
        'old_values': oldValues,
        'new_values': newValues,
        'changed_fields': changedFields,
        'request_id': requestId,
        'endpoint': endpoint,
        'http_method': httpMethod,
        'status_code': statusCode,
      }),
    ));

    return _parseResponse(response);
  }

  static Future<Map<String, String>?> getAuthHeaders() async {
    return _buildAuthHeaders();
  }

  static Map<String, String> _buildAuthHeaders() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_accessToken != null) {
      headers['Authorization'] = 'Bearer $_accessToken';
    }
    return headers;
  }

  static Future fetchUserProfile() async {}

  // Dashboard methods
  static Future<Map<String, dynamic>> getDashboardData() async {
    final response = await _makeRequest(() => http.get(
      Uri.parse('$baseUrl/analytics/dashboard'),
      headers: _getHeaders(),
    ));
    
    final data = _parseResponse(response);
    
    // Use type-safe conversion for dashboard data
    if (data is Map<String, dynamic>) {
      return _convertDashboardData(data);
    }
    
    return {};
  }

  // Helper method to convert dashboard data with type safety
  static Map<String, dynamic> _convertDashboardData(Map<String, dynamic> data) {
    final converted = Map<String, dynamic>.from(data);
    
    // Convert common fields that might have type mismatches
    converted['total_sprints'] = toInt(data['total_sprints'] ?? 0);
    converted['active_sprints'] = toInt(data['active_sprints'] ?? 0);
    converted['completed_sprints'] = toInt(data['completed_sprints'] ?? 0);
    converted['total_deliverables'] = toInt(data['total_deliverables'] ?? 0);
    converted['pending_deliverables'] = toInt(data['pending_deliverables'] ?? 0);
    converted['completed_deliverables'] = toInt(data['completed_deliverables'] ?? 0);
    converted['overdue_deliverables'] = toInt(data['overdue_deliverables'] ?? 0);
    
    // Convert user-related fields
    if (data.containsKey('recent_users') && data['recent_users'] is List) {
      converted['recent_users'] = (data['recent_users'] as List).map((user) {
        if (user is Map<String, dynamic>) {
          final userMap = Map<String, dynamic>.from(user);
          userMap['id'] = toInt(user['id']);
          userMap['user_id'] = toInt(user['user_id']);  // user_id should be integer
          userMap['email'] = toStr(user['email'] ?? '');
          userMap['first_name'] = toStr(user['first_name'] ?? '');
          userMap['last_name'] = toStr(user['last_name'] ?? '');
          return userMap;
        }
        return user;
      }).toList();
    }
    
    // Convert sprint statistics
    if (data.containsKey('sprint_stats') && data['sprint_stats'] is List) {
      converted['sprint_stats'] = (data['sprint_stats'] as List).map((stat) {
        if (stat is Map<String, dynamic>) {
          final statMap = Map<String, dynamic>.from(stat);
          statMap['sprint_id'] = toInt(stat['sprint_id']);
          statMap['planned_points'] = toInt(stat['planned_points']);
          statMap['completed_points'] = toInt(stat['completed_points']);
          statMap['completion_percentage'] = toInt(stat['completion_percentage'] ?? 0);
          return statMap;
        }
        return stat;
      }).toList();
    }
    
    return converted;
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


}