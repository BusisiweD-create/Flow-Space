import 'dart:convert';
import 'dart:io';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/environment.dart';
import 'package:flutter/foundation.dart';

class ApiClient {
  static final ApiClient _instance = ApiClient._internal();
  factory ApiClient() => _instance;
  ApiClient._internal();

  static String get _baseUrlWithVersion => Environment.apiBaseUrl;
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
    debugPrint('API Client initialized with base URL: $_baseUrlWithVersion');
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
        Uri.parse('$_baseUrlWithVersion/auth/refresh'),
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

  // Multipart file upload method
  Future<ApiResponse> uploadFile(String endpoint, String filePath, String fileName, String fileType, {Map<String, String>? fields}) async {
    try {
      // Check if token needs refresh
      if (_accessToken != null && !_isTokenValid()) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          await clearTokens();
          return ApiResponse.error('Authentication expired. Please login again.');
        }
      }

      // Build URL
      final String url = '$_baseUrlWithVersion$endpoint';

      // Create multipart request
      final request = http.MultipartRequest('POST', Uri.parse(url));

      // Add authorization header
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      // Add file
      request.files.add(await http.MultipartFile.fromPath(
        'file',
        filePath,
        filename: fileName,
      ),);

      // Add additional fields
      if (fields != null) {
        fields.forEach((key, value) {
          request.fields[key] = value;
        });
      }

      // Add file type field
      request.fields['fileType'] = fileType;

      // Send request
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      // Convert to regular response
      final httpResponse = http.Response(responseBody, response.statusCode);
      return _handleResponse(httpResponse);
    } on SocketException {
      return ApiResponse.error('No internet connection. Please check your network.');
    } on HttpException catch (e) {
      return ApiResponse.error('HTTP error: ${e.message}');
    } catch (e) {
      debugPrint('File upload error: $e');
      return ApiResponse.error('An unexpected error occurred during file upload: $e');
    }
  }

  Future<ApiResponse> _makeRequest(
    String method,
    String endpoint, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    try {
      // Check if token needs refresh
      if (_accessToken != null && !_isTokenValid()) {
        final refreshed = await _refreshAccessToken();
        if (!refreshed) {
          await clearTokens();
          return ApiResponse.error('Authentication expired. Please login again.');
        }
      }

      // Build URL
      String url = '$_baseUrlWithVersion$endpoint';
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
      
      debugPrint('Request Headers: $headers');

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
      final rawBody = response.body;
      if (response.statusCode == 204 || rawBody.trim().isEmpty) {
        return ApiResponse.success(null, response.statusCode);
      }
      // Check if response is HTML (error pages) instead of JSON
      final contentType = response.headers['content-type'] ?? '';
      if (contentType.contains('text/html') || response.body.trim().startsWith('<!DOCTYPE')) {
        // Server returned HTML (likely a 404 or error page)
        String errorMsg = 'Server returned HTML instead of JSON';
        if (response.statusCode == 404) {
          errorMsg = 'Endpoint not found (404). Check the API endpoint path.';
        } else if (response.statusCode >= 500) {
          errorMsg = 'Server error (${response.statusCode})';
        }
        return ApiResponse.error(errorMsg, response.statusCode);
      }
      
      final responseBody = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (responseBody == null) {
          return ApiResponse.success(null, response.statusCode);
        }

        // Support top-level lists (e.g., files, users collections)
        if (responseBody is List) {
          return ApiResponse.success(responseBody, response.statusCode);
        }

        // From here on, raw must be a Map-like structure
        if (responseBody is! Map) {
          return ApiResponse.success(responseBody, response.statusCode);
        }

        final Map<String, dynamic> body = responseBody as Map<String, dynamic>;

        // 1) Standard format: { success: true, data: ... }
        final bool isStandardFormat = body['success'] == true && body.containsKey('data');
        // 2) Auth format: { token: '...', user: {...} }
        final bool isAuthFormat = body.containsKey('token') || body.containsKey('user');

        if (isStandardFormat) {
          final data = body['data'];
          return ApiResponse.success(data, response.statusCode);
        }

        if (isAuthFormat) {
          return ApiResponse.success(body, response.statusCode);
        }

        // 3) Fallback: return entire map as data
        return ApiResponse.success(body, response.statusCode);
      } else {
        if (responseBody is Map) {
          final Map<String, dynamic> body = responseBody as Map<String, dynamic>;
          final errorMessage = body['message']?.toString() ?? body['error']?.toString() ?? 'Request failed';
          return ApiResponse.error(errorMessage, response.statusCode);
        }
        return ApiResponse.error('Request failed', response.statusCode);
      }
    } catch (e) {
      // If JSON parsing fails, provide a more helpful error message
      String errorMsg = 'Invalid response format: $e';
      if (response.body.trim().startsWith('<!DOCTYPE')) {
        errorMsg = 'Server returned HTML instead of JSON. Check if the endpoint exists.';
      }
      return ApiResponse.error(errorMsg, response.statusCode);
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
      final accessToken = data['token'] ?? data['access_token'];
      final refreshToken = data['refresh_token'] ?? '';
      final expiresIn = data['expires_in'] ?? 86400;
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
        
        await saveTokens(accessToken, refreshToken, expiry);
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
      'currentPassword': currentPassword,
      'newPassword': newPassword,
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
  final dynamic data; // Changed to dynamic to support both Map and List
  final String? error;
  final int statusCode;

  ApiResponse._({
    required this.isSuccess,
    this.data,
    this.error,
    required this.statusCode,
  });

  factory ApiResponse.success(dynamic data, int statusCode) {
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

  String? get deliverableId => null;

  @override
  String toString() {
    return 'ApiResponse(isSuccess: $isSuccess, data: $data, error: $error, statusCode: $statusCode)';
  }
}
