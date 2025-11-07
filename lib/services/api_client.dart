import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static const String _baseUrl = 'http://localhost:3007/api'; // Local backend server
  static const String _apiVersion = '/v1';
  static const Duration _timeout = Duration(seconds: 30);

  String? _accessToken;
  String? _refreshToken;
  DateTime? _tokenExpiry;

  // Getters
  String? get accessToken => _accessToken;
  bool get isAuthenticated => _accessToken != null && _isTokenValid();
  
  // Get auth token for API calls
  String? getAuthToken() => _accessToken;

  // Initialize API client
  Future<void> initialize() async {
    await _loadStoredTokens();
    debugPrint('API Client initialized with base URL: $_baseUrl');
  }

  // Token management
  Future<void> _loadStoredTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('access_token');
      _refreshToken = prefs.getString('refresh_token');
      final expiryString = prefs.getString('token_expiry');
      if (expiryString != null) {
        _tokenExpiry = DateTime.parse(expiryString);
      }
    } catch (e) {
      debugPrint('Error loading stored tokens: $e');
    }
  }

  Future<void> saveTokens(String accessToken, String refreshToken, DateTime expiry) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('access_token', accessToken);
      await prefs.setString('refresh_token', refreshToken);
      await prefs.setString('token_expiry', expiry.toIso8601String());
      
      _accessToken = accessToken;
      _refreshToken = refreshToken;
      _tokenExpiry = expiry;
    } catch (e) {
      debugPrint('Error saving tokens: $e');
    }
  }

  Future<void> clearTokens() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('access_token');
      await prefs.remove('refresh_token');
      await prefs.remove('token_expiry');
      
      _accessToken = null;
      _refreshToken = null;
      _tokenExpiry = null;
    } catch (e) {
      debugPrint('Error clearing tokens: $e');
    }
  }

  bool _isTokenValid() {
    if (_tokenExpiry == null) return false;
    return DateTime.now().isBefore(_tokenExpiry!.subtract(const Duration(minutes: 5)));
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl$_apiVersion/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_refreshToken',
        },
        body: jsonEncode({
          'refresh_token': _refreshToken,
        }),
      ).timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'] ?? _refreshToken;
        final expiry = DateTime.now().add(Duration(seconds: data['expires_in'] ?? 3600));
        
        await saveTokens(newAccessToken, newRefreshToken, expiry);
        return true;
      }
    } catch (e) {
      debugPrint('Error refreshing token: $e');
    }
    return false;
  }

  // HTTP Methods
  Future<ApiResponse> get(String endpoint, {Map<String, String>? queryParams}) async {
    return await _makeRequest('GET', endpoint, queryParams: queryParams);
  }

  Future<ApiResponse> post(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    return await _makeRequest('POST', endpoint, body: body, queryParams: queryParams);
  }

  Future<ApiResponse> put(String endpoint, {Map<String, dynamic>? body, Map<String, String>? queryParams}) async {
    return await _makeRequest('PUT', endpoint, body: body, queryParams: queryParams);
  }

  Future<ApiResponse> delete(String endpoint, {Map<String, String>? queryParams}) async {
    return await _makeRequest('DELETE', endpoint, queryParams: queryParams);
  }

  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      // Check if token needs refresh
      if (isAuthenticated && !_isTokenValid()) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          await clearTokens();
          return ApiResponse.error('Authentication expired. Please login again.');
        }
      }

      // Build URL
      String url = '$_baseUrl$_apiVersion$endpoint';
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        url = uri.replace(queryParameters: queryParams).toString();
      }

      // Prepare headers
      final headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

      if (_accessToken != null) {
        headers['Authorization'] = 'Bearer $_accessToken';
      }

      // Make request
      http.Response response;
      switch (method.toUpperCase()) {
        case 'GET':
          response = await http.get(Uri.parse(url), headers: headers).timeout(_timeout);
          break;
        case 'POST':
          response = await http.post(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_timeout);
          break;
        case 'PUT':
          response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: body != null ? jsonEncode(body) : null,
          ).timeout(_timeout);
          break;
        case 'DELETE':
          response = await http.delete(Uri.parse(url), headers: headers).timeout(_timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      return _handleResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      return ApiResponse.error('HTTP error: ${e.message}');
    } catch (e) {
      debugPrint('API request error: $e');
      return ApiResponse.error('An unexpected error occurred: $e');
    }
  }

  ApiResponse _handleResponse(http.Response response) {
    try {
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Extract the 'data' field from the backend response
        // Backend response structure: { success: true, message: '...', data: {...} }
        final data = responseBody['data'] ?? responseBody;
        return ApiResponse.success(data, response.statusCode);
      } else {
        final errorMessage = responseBody['message'] ?? responseBody['error'] ?? 'Request failed';
        return ApiResponse.error(errorMessage, response.statusCode);
      }
    } catch (e) {
      return ApiResponse.error('Invalid response format: $e', response.statusCode);
    }
  }

  // Authentication methods
  Future<ApiResponse> login(String email, String password) async {

    final response = await post('/auth/login', body: {
      'email': email,
      'password': password,
    },);

    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final accessToken = data['token'] ?? data['access_token']; // Handle both 'token' and 'access_token'
      final refreshToken = data['refresh_token'] ?? ''; // Handle null refresh token
      final expiresIn = data['expires_in'] ?? 86400; // Default to 24 hours
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));
      
      await saveTokens(accessToken, refreshToken, expiry);
    }

    return response;
  }

  Future<ApiResponse> register(String email, String password, String name, String role) async {
    // Parse the full name into firstName and lastName for the backend
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts[0] : '';
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    final response = await post('/auth/register', body: {
      'email': email,
      'password': password,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    },);

    // Save tokens if registration is successful
    if (response.isSuccess && response.data != null) {
      final data = response.data!;
      final accessToken = data['token']; // Backend returns 'token' in registration
      if (accessToken != null) {
        final refreshToken = data['refresh_token'] ?? '';
        final expiresIn = data['expires_in'] ?? 86400; // Default to 24 hours
        final expiry = DateTime.now().add(Duration(seconds: expiresIn));
        
        await _saveTokens(accessToken, refreshToken, expiry);
      }
    }

    return response;
  }

  Future<ApiResponse> logout() async {

    final response = await post('/auth/logout');
    await clearTokens();
    return response;
  }

  Future<ApiResponse> getCurrentUser() async {

    return await get('/auth/me');
  }

  Future<ApiResponse> updateProfile(Map<String, dynamic> updates) async {
    return await put('/auth/profile', body: updates);
  }

  Future<ApiResponse> changePassword(String currentPassword, String newPassword) async {
    return await post('/auth/change-password', body: {
      'current_password': currentPassword,
      'new_password': newPassword,
    },);
  }

  Future<ApiResponse> forgotPassword(String email) async {
    return await post('/auth/forgot-password', body: {
      'email': email,
    },);
  }

  Future<ApiResponse> resetPassword(String token, String newPassword) async {
    return await post('/auth/reset-password', body: {
      'token': token,
      'password': newPassword,
    },);
  }
}

class ApiResponse {
  final bool isSuccess;
  final Map<String, dynamic>? data;
  final String? error;
  final int statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(Map<String, dynamic> data, int statusCode) {
    return ApiResponse._(
      isSuccess: true,
      data: data,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error(String error, [int statusCode = 0]) {
    return ApiResponse._(
      isSuccess: false,
      error: error,
      statusCode: statusCode,
    );
  }

  @override
  String toString() {
    return 'ApiResponse(isSuccess: $isSuccess, data: $data, error: $error, statusCode: $statusCode)';
  }
}
