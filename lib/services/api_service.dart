import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../models/system_metrics.dart';

class ApiService {
  // Base URL for your backend API (you'll need to create this)
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Get auth headers with token
  static Future<Map<String, String>> _getHeaders() async {
    final authService = AuthService();
    await authService.initialize();
    final token = authService.accessToken;
    
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }
  
  // Initialize the service
  static Future<void> initialize() async {
    debugPrint('API Service initialized');
  }
  
  // Authentication methods
  static Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String company,
    required String role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'firstName': firstName,
          'lastName': lastName,
          'company': company,
          'role': role,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 409) {
        // User already exists - return error details
        final responseBody = jsonDecode(response.body);
        debugPrint('Sign up failed: User already exists - ${responseBody['error'] ?? response.body}');
        return {
          'error': responseBody['error'] ?? 'User already exists',
          'message': responseBody['message'] ?? 'A user with this email already exists',
          'statusCode': response.statusCode,
        };
      } else {
        debugPrint('Sign up failed: ${response.statusCode} - ${response.body}');
        return {
          'error': 'Registration failed',
          'message': 'Failed to create account. Please try again.',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      debugPrint('Error during sign up: $e');
      return {
        'error': 'Network error',
        'message': 'Failed to connect to server. Please check your connection.',
      };
    }
  }
  
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Sign in failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error during sign in: $e');
      return null;
    }
  }
  
  // Database methods for deliverables
  static Future<List<Map<String, dynamic>>> getDeliverables() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deliverables'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch deliverables: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching deliverables: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>?> createDeliverable({
    required String title,
    required String description,
    required String definitionOfDone,
    required String status,
    required String assignedTo,
    required String createdBy,
  }) async {
    try {
      debugPrint('Creating deliverable: $title');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/v1/deliverables'),
        headers: headers,
        body: jsonEncode({
          'title': title,
          'description': description,
          'definition_of_done': definitionOfDone,
          'status': status,
          'assigned_to': assignedTo,
          'created_by': createdBy,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          debugPrint('✅ Deliverable created successfully');
          return data['data'];
        }
      }
      
      // Parse error details from response
      try {
        final errorData = jsonDecode(response.body);
        final errorMessage = errorData['details'] ?? errorData['error'] ?? 'Unknown error';
        final errorCode = errorData['code'];
        final errorDetail = errorData['detail'];
        
        debugPrint('❌ Failed to create deliverable: ${response.statusCode}');
        debugPrint('   Error: $errorMessage');
        if (errorCode != null) debugPrint('   Code: $errorCode');
        if (errorDetail != null) debugPrint('   Detail: $errorDetail');
        debugPrint('   Full response: ${response.body}');
      } catch (e) {
        debugPrint('❌ Failed to create deliverable: ${response.statusCode}');
        debugPrint('   Response body: ${response.body}');
      }
      
      return null;
    } catch (e) {
      debugPrint('Error creating deliverable: $e');
      return null;
    }
  }
  
  static Future<void> updateDeliverableStatus({
    required String id,
    required String status,
  }) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/deliverables/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'status': status}),
      );
    } catch (e) {
      debugPrint('Error updating deliverable status: $e');
    }
  }
  
  // Database methods for projects
  static Future<List<Map<String, dynamic>>> getProjects() async {
    try {
      debugPrint('Fetching projects from database');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/v1/projects'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Fetched ${data['data'].length} projects from database');
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      debugPrint('❌ Failed to fetch projects: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching projects: $e');
      return [];
    }
  }
  
  // Database methods for sprints
  static Future<List<Map<String, dynamic>>> getSprints() async {
    try {
      debugPrint('Fetching sprints from database');
      
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/v1/sprints'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          debugPrint('✅ Fetched ${data['data'].length} sprints from database');
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      
      debugPrint('❌ Failed to fetch sprints: ${response.statusCode}');
      return [];
    } catch (e) {
      debugPrint('Error fetching sprints: $e');
      return [];
    }
  }

  // Update sprint status
  static Future<bool> updateSprintStatus(String sprintId, String newStatus) async {
    try {
      debugPrint('Updating sprint $sprintId status to $newStatus');
      
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/v1/sprints/$sprintId'),
        headers: headers,
        body: jsonEncode({'status': newStatus}),
      );
      
      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');
      
      if (response.statusCode == 200) {
        debugPrint('✅ Sprint status updated successfully');
        return true;
      }
      
      debugPrint('❌ Failed to update sprint status: ${response.statusCode}');
      debugPrint('Error response: ${response.body}');
      return false;
    } catch (e) {
      debugPrint('Error updating sprint status: $e');
      return false;
    }
  }

  // Create a new project
  static Future<Map<String, dynamic>?> createProject({
    required String name,
    required String key,
    String? description,
  }) async {
    try {
      debugPrint('Creating project: $name ($key)');
      
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/v1/projects'),
        headers: headers,
        body: jsonEncode({
          'name': name,
          'key': key,
          'description': description ?? '',
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Project created successfully');
        return data['data'] ?? data;
      }
      
      debugPrint('❌ Failed to create project: ${response.statusCode}');
      return null;
    } catch (e) {
      debugPrint('Error creating project: $e');
      return null;
    }
  }
  
  static Future<Map<String, dynamic>?> createSprint({
    required String name,
    required DateTime startDate,
    required DateTime endDate,
    required int plannedPoints,
    required int completedPoints,
    required String createdBy, required String description, int? committedPoints, int? carriedOverPoints, int? addedDuringSprint, int? removedDuringSprint, int? testPassRate, int? codeCoverage, int? escapedDefects, int? defectsOpened, int? defectsClosed, required String defectSeverityMix, int? codeReviewCompletion, required String documentationStatus, required String uatNotes, int? uatPassRate, int? risksIdentified, int? risksMitigated, required String blockers, required String decisions,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sprints'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'startDate': startDate.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'plannedPoints': plannedPoints,
          'completedPoints': completedPoints,
          'createdBy': createdBy,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create sprint: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating sprint: $e');
      return null;
    }
  }

  // Sprint metrics methods
  static Future<List<Map<String, dynamic>>> getSprintMetrics(String sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sprints/$sprintId/metrics'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['metrics']);
      } else {
        debugPrint('Failed to load sprint metrics: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading sprint metrics: $e');
      return [];
    }
  }

  // Sign-off report methods
  static Future<Map<String, dynamic>?> createSignOffReport({
    required String deliverableId,
    required String reportTitle,
    required String reportContent,
    String? sprintPerformanceData,
    String? knownLimitations,
    String? nextSteps,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/sign-off-reports'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'deliverable_id': deliverableId,
          'report_title': reportTitle,
          'report_content': reportContent,
          'sprint_performance_data': sprintPerformanceData,
          'known_limitations': knownLimitations,
          'next_steps': nextSteps,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create sign-off report: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating sign-off report: $e');
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> getSignOffReports() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sign-off-reports'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['reports']);
      } else {
        debugPrint('Failed to load sign-off reports: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading sign-off reports: $e');
      return [];
    }
  }

  // Client review methods
  static Future<Map<String, dynamic>?> submitClientReview({
    required String signOffReportId,
    required String reviewStatus,
    String? reviewComments,
    String? changeRequestDetails,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/client-reviews'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sign_off_report_id': signOffReportId,
          'review_status': reviewStatus,
          'review_comments': reviewComments,
          'change_request_details': changeRequestDetails,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to submit client review: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error submitting client review: $e');
      return null;
    }
  }

  // Release readiness methods
  static Future<List<Map<String, dynamic>>> getReleaseReadinessChecks(String deliverableId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deliverables/$deliverableId/readiness-checks'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['checks']);
      } else {
        debugPrint('Failed to load readiness checks: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading readiness checks: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> updateReadinessCheck({
    required String checkId,
    required bool isPassed,
    String? checkDetails,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/readiness-checks/$checkId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'is_passed': isPassed,
          'check_details': checkDetails,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to update readiness check: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error updating readiness check: $e');
      return null;
    }
  }

  static Future getDashboardData() async {}

  // Repository file methods
  static Future<List<Map<String, dynamic>>> getProjectFiles(String projectId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/projects/$projectId/files'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['files'] ?? []);
      } else {
        debugPrint('Failed to fetch project files: \${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching project files: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> uploadFile({
    required String projectId,
    required String fileName,
    required String fileType,
    required String description,
    required String filePath,
    Uint8List? fileBytes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/projects/$projectId/files'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fileName': fileName,
          'filePath': filePath,
          'fileType': fileType,
          'description': description,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to upload file: \${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error uploading file: $e');
      return null;
    }
  }

  // System metrics methods
  static Future<SystemMetrics> getSystemMetrics() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/system-metrics'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return SystemMetrics.fromJson(data);
      } else {
        debugPrint('Failed to load system metrics: ${response.statusCode}');
        // Return mock data for development
        return _getMockSystemMetrics();
      }
    } catch (e) {
      debugPrint('Error loading system metrics: $e');
      // Return mock data for development
      return _getMockSystemMetrics();
    }
  }

  // Mock system metrics for development
  static SystemMetrics _getMockSystemMetrics() {
    return SystemMetrics(
      systemHealth: SystemHealthStatus.healthy,
      performance: PerformanceMetrics(
        cpuUsage: 23.4,
        memoryUsage: 512.3,
        diskUsage: 32.1,
        responseTime: 45,
        uptime: 99.8,
      ),
      database: DatabaseMetrics(
        totalRecords: 156,
        activeConnections: 8,
        cacheHitRatio: 0.95,
        queryCount: 12543,
        slowQueries: 63,
      ),
      userActivity: UserActivityMetrics(
        activeUsers: 18,
        totalSessions: 342,
        newRegistrations: 5,
        failedLogins: 2,
        avgSessionDuration: 12.5,
      ),
      lastUpdated: DateTime.now(),
    );
  }

  static Future<bool> deleteFile(String fileId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/files/$fileId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Settings methods
  static Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/settings'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to fetch user settings: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user settings: $e');
      return null;
    }
  }

  static Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/user/settings'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(settings),
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating user settings: $e');
      return false;
    }
  }

  static Future<bool> resetUserSettings() async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/settings/reset'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error resetting user settings: $e');
      return false;
    }
  }

  static Future<bool> exportUserData() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/user/data/export'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      return false;
    }
  }

  static Future<bool> clearUserCache() async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/user/cache'),
        headers: {'Content-Type': 'application/json'},
      );
      
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error clearing user cache: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSprintTickets(String sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sprints/$sprintId/tickets'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['tickets'] ?? []);
      } else {
        debugPrint('Failed to load sprint tickets: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading sprint tickets: $e');
      return [];
    }
  }
}
