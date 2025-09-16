import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/environment.dart';

class ApiService {
  // Base URL for the backend API
  static const String baseUrl = Environment.apiBaseUrl;
  
  // Initialize the service
  static Future<void> initialize() async {
    debugPrint('API Service initialized');
  }
  
  // Health checks
  static Future<bool> health() async {
    try {
      final response = await http.get(Uri.parse(baseUrl.replaceFirst('/api/v1', '/health')));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> root() async {
    try {
      final response = await http.get(Uri.parse(baseUrl.replaceFirst('/api/v1', '/')));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
  
  // Authentication methods (placeholder; backend has no auth routes yet)
  static Future<Map<String, dynamic>?> signUp({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String company,
    required String role,
  }) async {
    debugPrint('signUp not implemented on backend');
    return null;
  }
  
  static Future<Map<String, dynamic>?> signIn({
    required String email,
    required String password,
  }) async {
    debugPrint('signIn not implemented on backend');
    return null;
  }
  
  // Deliverables
  static Future<List<Map<String, dynamic>>> getDeliverables({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deliverables?skip=$skip&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch deliverables: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching deliverables: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>?> createDeliverable({
    required String title,
    String? description,
    String? definitionOfDone,
    String status = 'pending',
    int? sprintId,
    String? assignedTo,
    String? createdBy,
  }) async {
    try {
      final response = await http.post(
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
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create deliverable: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating deliverable: $e');
      return null;
    }
  }
  
  static Future<Map<String, dynamic>?> updateDeliverable({
    required int id,
    String? title,
    String? description,
    String? status,
    int? sprintId,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/deliverables/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': title,
          'description': description,
          'status': status,
          'sprint_id': sprintId,
        }),
      );
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to update deliverable: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error updating deliverable: $e');
      return null;
    }
  }
  
  static Future<bool> deleteDeliverable(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/deliverables/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting deliverable: $e');
      return false;
    }
  }

  static Future<List<Map<String, dynamic>>> getDeliverablesBySprint(int sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/deliverables/sprint/$sprintId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch deliverables by sprint: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching deliverables by sprint: $e');
      return [];
    }
  }
  
  // Sprints
  static Future<List<Map<String, dynamic>>> getSprints({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sprints?skip=$skip&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch sprints: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching sprints: $e');
      return [];
    }
  }
  
  static Future<Map<String, dynamic>?> createSprint({
    required String name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String status = 'planning',
    int? plannedPoints,
    int? completedPoints,
    String? createdBy,
  }) async {
    try {
      final response = await http.post(
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
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create sprint: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating sprint: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateSprint({
    required int id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/sprints/$id'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'description': description,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
          'status': status,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to update sprint: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error updating sprint: $e');
      return null;
    }
  }

  static Future<bool> deleteSprint(int id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/sprints/$id'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting sprint: $e');
      return false;
    }
  }

  // Signoff
  static Future<List<Map<String, dynamic>>> getSignoffsBySprint(int sprintId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/signoff/sprint/$sprintId'),
        headers: {'Content-Type': 'application/json'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch signoffs: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching signoffs: $e');
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signoff'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sprint_id': sprintId,
          'signer_name': signerName,
          'signer_email': signerEmail,
          'comments': comments,
          'is_approved': isApproved,
        }),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create signoff: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating signoff: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> approveSignoff(int signoffId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/signoff/$signoffId/approve'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to approve signoff: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error approving signoff: $e');
      return null;
    }
  }

  // Audit Logs
  static Future<List<Map<String, dynamic>>> getAuditLogs({int skip = 0, int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit?skip=$skip&limit=$limit'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch audit logs: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching audit logs: $e');
      return [];
    }
  }

  static Future<List<Map<String, dynamic>>> getAuditLogsForEntity({
    required String entityType,
    required int entityId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/audit/entity/$entityType/$entityId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data);
      } else {
        debugPrint('Failed to fetch audit logs by entity: ${response.statusCode} - ${response.body}');
        return [];
      }
    } catch (e) {
      debugPrint('Error fetching audit logs by entity: $e');
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
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/audit'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'entity_type': entityType,
          'entity_id': entityId,
          'action': action,
          'user': user,
          'details': details,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Failed to create audit log: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error creating audit log: $e');
      return null;
    }
  }
}
