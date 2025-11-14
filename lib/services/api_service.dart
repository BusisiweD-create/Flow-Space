import 'dart:convert';
import 'package:flutter/foundation.dart';
// ignore: depend_on_referenced_packages
import 'package:http/http.dart' as http;
import '../models/system_metrics.dart';
import 'backend_api_service.dart';

class ApiService {
  // Base URL for your backend API (you'll need to create this)
  static const String baseUrl = 'http://localhost:8000/api';
  
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
      final backendService = BackendApiService();
      final response = await backendService.getDeliverables();
      
      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!['data'] ?? response.data!['deliverables'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch deliverables: ${response.statusCode} - ${response.error}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching deliverables: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>?> getDeliverable(String deliverableId) async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getDeliverable(deliverableId);
      
      if (response.isSuccess && response.data != null) {
        return response.data!['data'] ?? response.data!['deliverable'];
      } else {
        debugPrint('Failed to fetch deliverable: ${response.statusCode} - ${response.error}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching deliverable: $e');
      return null;
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
      final backendService = BackendApiService();
      final response = await backendService.createDeliverable({
        'title': title,
        'description': description,
        'definition_of_done': definitionOfDone,
        'status': status,
        'assigned_to': assignedTo,
        'created_by': createdBy,
      });

      if (response.isSuccess && response.data != null) {
        return response.data!['data'] ?? response.data!['deliverable'] ?? response.data!;
      } else {
        debugPrint('Failed to create deliverable: ${response.statusCode} - ${response.error}');
        return null;
      }
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
  
  // Database methods for sprints
  static Future<List<Map<String, dynamic>>> getSprints() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getSprints();
      
      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!['data'] ?? response.data!['sprints'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch sprints: ${response.statusCode} - ${response.error}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching sprints: $e');
      return [];
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
      final backendService = BackendApiService();
      final response = await backendService.getSprintMetrics(sprintId);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!['data'] ?? response.data!['metrics'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to load sprint metrics: ${response.statusCode} - ${response.error}');
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
      final backendService = BackendApiService();
      final response = await backendService.listFiles(prefix: projectId);
      
      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!;
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to fetch project files: ${response.statusCode} - ${response.error}');
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
      final backendService = BackendApiService();
      final response = await backendService.uploadFile(filePath, fileName, fileType);
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        debugPrint('Failed to upload file: ${response.statusCode} - ${response.error}');
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
      final backendService = BackendApiService();
      final response = await backendService.getSystemStats();

      if (response.isSuccess && response.data != null) {
        final data = response.data!;
        // Extract system metrics from the stats response with proper type conversion
        final systemMetrics = SystemMetrics(
          systemHealth: SystemHealthStatus.healthy,
          performance: PerformanceMetrics(
            cpuUsage: _parseDouble(data['system']?['cpuUsage']) ?? 0.0,
            memoryUsage: _parseDouble(data['system']?['memoryUsage']) ?? 0.0,
            diskUsage: _parseDouble(data['system']?['diskUsage']) ?? 0.0,
            responseTime: _parseInt(data['system']?['responseTime']) ?? 0,
            uptime: _parseDouble(data['system']?['uptime']) ?? 0.0,
          ),
          database: DatabaseMetrics(
            totalRecords: _parseInt(data['statistics']?['totalEntities']) ?? 0,
            activeConnections: _parseInt(data['system']?['activeConnections']) ?? 0,
            cacheHitRatio: _parseDouble(data['system']?['cacheHitRatio']) ?? 0.0,
            queryCount: _parseInt(data['system']?['queryCount']) ?? 0,
            slowQueries: _parseInt(data['system']?['slowQueries']) ?? 0,
          ),
          userActivity: UserActivityMetrics(
            activeUsers: _parseInt(data['statistics']?['users']) ?? 0,
            totalSessions: _parseInt(data['system']?['totalSessions']) ?? 0,
            newRegistrations: _parseInt(data['system']?['newRegistrations']) ?? 0,
            failedLogins: _parseInt(data['system']?['failedLogins']) ?? 0,
            avgSessionDuration: _parseDouble(data['system']?['avgSessionDuration']) ?? 0.0,
          ),
          lastUpdated: DateTime.now(),
        );
        return systemMetrics;
      } else {
        debugPrint('Failed to load system metrics: ${response.statusCode} - ${response.error}');
        // Return mock data for development
        throw Exception('Failed to load system metrics: ${response.statusCode} - ${response.error}');
      }
    } catch (e) {
      debugPrint('Error loading system metrics: $e');
      // Return mock data for development
      throw Exception('Error loading system metrics: $e');
    }
  }

  // Helper methods for type conversion
  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  // Mock system metrics for development

  static Future<bool> deleteFile(String fileId) async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.deleteFile(fileId);
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error deleting file: $e');
      return false;
    }
  }

  // Settings methods
  static Future<Map<String, dynamic>?> getUserSettings() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getUserSettings();
      
      if (response.isSuccess && response.data != null) {
        return response.data!;
      } else {
        debugPrint('Failed to fetch user settings: ${response.statusCode} - ${response.error}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching user settings: $e');
      return null;
    }
  }

  static Future<bool> updateUserSettings(Map<String, dynamic> settings) async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.updateUserSettings(settings);
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error updating user settings: $e');
      return false;
    }
  }

  static Future<bool> resetUserSettings() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.resetUserSettings();
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error resetting user settings: $e');
      return false;
    }
  }

  static Future<bool> exportUserData() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.exportUserData();
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error exporting user data: $e');
      return false;
    }
  }

  static Future<bool> clearUserCache() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.clearUserCache();
      
      return response.isSuccess;
    } catch (e) {
      debugPrint('Error clearing user cache: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getSprintTickets(String sprintId) async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getSprintTickets(sprintId);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!['data'] ?? response.data!['tickets'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to load sprint tickets: ${response.statusCode} - ${response.error}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading sprint tickets: $e');
      return [];
    }
  }

  // QA-specific methods
  static Future<List<Map<String, dynamic>>> getTestQueue() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getTestQueue();

      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!['data'] ?? response.data!['testQueue'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to load test queue: ${response.statusCode} - ${response.error}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading test queue: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getQualityMetrics() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getQualityMetrics();

      if (response.isSuccess && response.data != null) {
        return response.data! as Map<String, dynamic>;
      } else {
        debugPrint('Failed to load quality metrics: ${response.statusCode} - ${response.error}');
        return {};
      }
    } catch (e) {
      debugPrint('Error loading quality metrics: $e');
      return {};
    }
  }

  static Future<List<Map<String, dynamic>>> getBugReports({int limit = 10}) async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getBugReports(limit: limit);

      if (response.isSuccess && response.data != null) {
        final List<dynamic> items = response.data!['data'] ?? response.data!['bugReports'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } else {
        debugPrint('Failed to load bug reports: ${response.statusCode} - ${response.error}');
        return [];
      }
    } catch (e) {
      debugPrint('Error loading bug reports: $e');
      return [];
    }
  }

  static Future<Map<String, dynamic>> getTestCoverage() async {
    try {
      final backendService = BackendApiService();
      final response = await backendService.getTestCoverage();

      if (response.isSuccess && response.data != null) {
        return response.data! as Map<String, dynamic>;
      } else {
        debugPrint('Failed to load test coverage: ${response.statusCode} - ${response.error}');
        return {};
      }
    } catch (e) {
      debugPrint('Error loading test coverage: $e');
      return {};
    }
  }
}
