import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // Base URL for your backend API (you'll need to create this)
  static const String baseUrl = 'http://localhost:3000/api';
  
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
      } else {
        debugPrint('Sign up failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error during sign up: $e');
      return null;
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
      final response = await http.post(
        Uri.parse('$baseUrl/deliverables'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'definitionOfDone': definitionOfDone,
          'status': status,
          'assignedTo': assignedTo,
          'createdBy': createdBy,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create deliverable: ${response.statusCode}');
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
      final response = await http.get(
        Uri.parse('$baseUrl/sprints'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch sprints: ${response.statusCode}');
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
    required String createdBy,
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
}
