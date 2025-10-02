// ignore_for_file: unused_element, body_might_complete_normally_nullable, unused_field, require_trailing_commas, dead_code, prefer_interpolation_to_compose_strings, unnecessary_import

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import '../utils/error_handler.dart';
import '../utils/retry_interceptor.dart';
import '../models/user.dart';

class ApiService {
  // Base URL for the backend API
  static const String baseUrl = Environment.apiBaseUrl;
  
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
  static Future<void> _saveTokens(String accessToken, String refreshToken, String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessTokenKey, accessToken);

    await prefs.setString(_userIdKey, userId);
    
    _accessToken = accessToken;

    _userId = userId;
  }
  
  // Clear tokens (logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessTokenKey);

    await prefs.remove(_userIdKey);
    
    _accessToken = null;

    _userId = null;
  }
  
  // Get current access token
  static String? get accessToken => _accessToken;
  
  // Get current user ID
  static String? get userId => _userId;
  
  // Get current user email
  static String? get currentUserEmail {
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
    // For now, return a placeholder or implement proper storage
    return 'authenticated@user.com';
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
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: 'username=${Uri.encodeComponent(email)}&password=${Uri.encodeComponent(password)}',
    ));
    
    final responseData = await _parseResponse(response);
    
    // Extract user ID from the access token (JWT)
    final accessToken = responseData['access_token'] as String;
    final tokenParts = accessToken.split('.');
    if (tokenParts.length != 3) {
      throw Exception('Invalid access token format');
    }
    
    final payload = utf8.decode(base64Url.decode(base64Url.normalize(tokenParts[1])));
    final Map<String, dynamic> claims = jsonDecode(payload);
    final userId = claims['sub'] as String;
    final userRole = claims['role'] as String;
    
    final tokenResponse = TokenResponse.fromJson({
      ...responseData,
      'user': {
        'id': int.parse(userId),
        'email': email,
        'first_name': '', // Will be populated from user profile
        'last_name': '',
        'role': userRole,
        'is_active': true,
        'is_verified': true,
        'created_at': DateTime.now().toIso8601String(),
      },
    });
    
    // Save tokens after successful signin
    await _saveTokens(
      tokenResponse.accessToken,
      tokenResponse.refreshToken,
      tokenResponse.user.id.toString(),
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
    int? sprintId,
    String? assignedTo,
    String? createdBy, 
    required String priority, 
    String? dueDate, 
    required List evidenceLinks, 
    required List<String> contributingSprints,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/deliverables'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'description': description,
        'definition_of_done': definitionOfDone,
        'status': status,
        'sprint_id': sprintId,
        'assigned_to': assignedTo,
        'created_by': createdBy,
        'priority': priority,
        'due_date': dueDate,
        'evidence_links': evidenceLinks,
        'contributing_sprints': contributingSprints,
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
    int? completedPoints,
    String? createdBy,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/sprints'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'description': description,
        'planned_points': plannedPoints,
        'completed_points': completedPoints,
        'start_date': startDate?.toIso8601String(),
        'end_date': endDate?.toIso8601String(),
        'status': status,
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
      }),
    ));

    return _parseResponse(response);
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
    String? user,
    String? details,
  }) async {
    final response = await _makeRequest(() => http.post(
      Uri.parse('$baseUrl/audit'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'entity_type': entityType,
        'entity_id': entityId,
        'action': action,
        'user': user,
        'details': details,
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


}