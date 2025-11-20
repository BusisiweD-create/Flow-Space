import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'api_client.dart';
import 'auth_service.dart';

class Deliverable {
  final String id;
  final String title;
  final String? description;
  final String? definitionOfDone;
  final String priority;
  final String status;
  final DateTime? dueDate;
  final String createdBy;
  final String? assignedTo;
  final String? sprintId;
  final String? createdByName;
  final String? assignedToName;
  final String? sprintName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Deliverable({
    required this.id,
    required this.title,
    this.description,
    this.definitionOfDone,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.createdBy,
    this.assignedTo,
    this.sprintId,
    this.createdByName,
    this.assignedToName,
    this.sprintName,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Deliverable.fromJson(Map<String, dynamic> json) {
    // Handle definition_of_done which can be a List (JSONB array) or String
    String? definitionOfDone;
    final dodValue = json['definition_of_done'];
    if (dodValue != null) {
      if (dodValue is List) {
        // Convert List to String by joining items
        definitionOfDone = dodValue.map((item) => item.toString()).join('\n');
      } else if (dodValue is String) {
        definitionOfDone = dodValue;
      }
    }
    
    return Deliverable(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      definitionOfDone: definitionOfDone,
      priority: json['priority']?.toString() ?? 'Medium',
      status: json['status']?.toString() ?? 'Draft',
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date'].toString()) : null,
      createdBy: json['created_by']?.toString() ?? '',
      assignedTo: json['assigned_to']?.toString(),
      sprintId: json['sprint_id']?.toString(),
      createdByName: json['created_by_name']?.toString(),
      assignedToName: json['assigned_to_name']?.toString(),
      sprintName: json['sprint_name']?.toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
      updatedAt: DateTime.parse(json['updated_at'].toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'definition_of_done': definitionOfDone,
      'priority': priority,
      'status': status,
      'due_date': dueDate?.toIso8601String(),
      'created_by': createdBy,
      'assigned_to': assignedTo,
      'sprint_id': sprintId,
      'created_by_name': createdByName,
      'assigned_to_name': assignedToName,
      'sprint_name': sprintName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class DeliverableService {
  final ApiClient _apiClient = ApiClient();
  final AuthService _authService = AuthService();

  // Get all deliverables
  Future<ApiResponse> getDeliverables() async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final response = await _apiClient.get('/deliverables');
      
      if (response.isSuccess && response.data != null) {
        try {
          // Handle different response structures
          List<dynamic> deliverablesJson = [];
          
          if (response.data is List) {
            // Direct list
            deliverablesJson = response.data as List<dynamic>;
          } else if (response.data is Map) {
            // Nested in 'data' or 'deliverables' key
            final data = response.data as Map<String, dynamic>;
            deliverablesJson = data['data'] as List<dynamic>? ?? 
                              data['deliverables'] as List<dynamic>? ?? 
                              [];
          }
          
          final List<Deliverable> deliverables = deliverablesJson
              .map((json) {
                try {
                  return Deliverable.fromJson(json as Map<String, dynamic>);
                } catch (e) {
                  debugPrint('Error parsing deliverable: $e, json: $json');
                  return null;
                }
              })
              .whereType<Deliverable>()
              .toList();
          
          return ApiResponse.success({'deliverables': deliverables}, response.statusCode);
        } catch (e) {
          debugPrint('Error processing deliverables response: $e');
          debugPrint('Response data type: ${response.data.runtimeType}');
          debugPrint('Response data: ${response.data}');
          return ApiResponse.error('Error processing deliverables: $e');
        }
      } else {
        return ApiResponse.error(response.error ?? 'Failed to fetch deliverables');
      }
    } catch (e, stackTrace) {
      debugPrint('Exception in getDeliverables: $e');
      debugPrint('Stack trace: $stackTrace');
      return ApiResponse.error('Error fetching deliverables: $e');
    }
  }

  // Create a new deliverable
  Future<ApiResponse> createDeliverable({
    required String title,
    String? description,
    dynamic definitionOfDone, // Can be List<String> or String
    String priority = 'Medium',
    String status = 'Draft',
    DateTime? dueDate,
    String? assignedTo,
    String? sprintId,
    List<String>? evidenceLinks,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      // Convert definitionOfDone to proper format for backend
      dynamic dodValue;
      if (definitionOfDone != null) {
        if (definitionOfDone is List<String>) {
          dodValue = definitionOfDone; // Send as array, backend will stringify
        } else if (definitionOfDone is String) {
          // If it's a string, try to parse it as JSON, otherwise wrap in array
          try {
            dodValue = jsonDecode(definitionOfDone);
          } catch (_) {
            dodValue = [definitionOfDone]; // Convert single string to array
          }
        } else {
          dodValue = definitionOfDone;
        }
      }

      final body = {
        'title': title,
        'description': description,
        'definition_of_done': dodValue,
        'priority': priority,
        'status': status,
        'due_date': dueDate?.toIso8601String(),
        'assigned_to': assignedTo,
        'sprint_id': sprintId,
        if (evidenceLinks != null) 'evidence_links': evidenceLinks,
      };

      final response = await _apiClient.post('/deliverables', body: body);
      
      if (response.isSuccess && response.data != null) {
        try {
          // ApiClient already extracts the 'data' field from backend response
          // So response.data should be the deliverable object directly
          Map<String, dynamic> deliverableJson;
          
          if (response.data is Map<String, dynamic>) {
            deliverableJson = response.data as Map<String, dynamic>;
          } else if (response.data is Map) {
            deliverableJson = Map<String, dynamic>.from(response.data as Map);
          } else {
            debugPrint('❌ Unexpected response data type: ${response.data.runtimeType}');
            debugPrint('📦 Response data: ${response.data}');
            return ApiResponse.error('Unexpected response format: ${response.data.runtimeType}');
          }
          
          if (deliverableJson.isEmpty) {
            return ApiResponse.error('Deliverable data is empty');
          }
          
          debugPrint('📦 Parsing deliverable from JSON: ${deliverableJson.keys}');
          final deliverable = Deliverable.fromJson(deliverableJson);
          return ApiResponse.success({'deliverable': deliverable}, response.statusCode);
        } catch (e, stackTrace) {
          debugPrint('❌ Error parsing deliverable response: $e');
          debugPrint('📚 Stack trace: $stackTrace');
          debugPrint('📦 Response data: ${response.data}');
          debugPrint('📦 Response data type: ${response.data.runtimeType}');
          return ApiResponse.error('Error parsing deliverable: $e');
        }
      } else {
        debugPrint('❌ Deliverable creation failed: ${response.error}');
        debugPrint('📦 Response status: ${response.statusCode}');
        return ApiResponse.error(response.error ?? 'Failed to create deliverable');
      }
    } catch (e) {
      return ApiResponse.error('Error creating deliverable: $e');
    }
  }

  // Update a deliverable
  Future<ApiResponse> updateDeliverable({
    required String id,
    String? title,
    String? description,
    String? definitionOfDone,
    String? priority,
    String? status,
    DateTime? dueDate,
    String? assignedTo,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (definitionOfDone != null) body['definition_of_done'] = definitionOfDone;
      if (priority != null) body['priority'] = priority;
      if (status != null) body['status'] = status;
      if (dueDate != null) body['due_date'] = dueDate.toIso8601String();
      if (assignedTo != null) body['assigned_to'] = assignedTo;

      final response = await _apiClient.put('/deliverables/$id', body: body);
      
      if (response.isSuccess && response.data != null) {
        try {
          // ApiClient already extracts the 'data' field from backend response
          Map<String, dynamic> deliverableJson;
          
          if (response.data is Map<String, dynamic>) {
            deliverableJson = response.data as Map<String, dynamic>;
          } else if (response.data is Map) {
            deliverableJson = Map<String, dynamic>.from(response.data as Map);
          } else {
            return ApiResponse.error('Unexpected response format: ${response.data.runtimeType}');
          }
          
          final deliverable = Deliverable.fromJson(deliverableJson);
          return ApiResponse.success({'deliverable': deliverable}, response.statusCode);
        } catch (e) {
          return ApiResponse.error('Error parsing deliverable: $e');
        }
      } else {
        return ApiResponse.error(response.error ?? 'Failed to update deliverable');
      }
    } catch (e) {
      return ApiResponse.error('Error updating deliverable: $e');
    }
  }

  // Delete a deliverable
  Future<ApiResponse> deleteDeliverable(String id) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final response = await _apiClient.delete('/deliverables/$id');
      
      if (response.isSuccess) {
        return ApiResponse.success({'message': 'Deliverable deleted successfully'}, response.statusCode);
      } else {
        return ApiResponse.error(response.error ?? 'Failed to delete deliverable');
      }
    } catch (e) {
      return ApiResponse.error('Error deleting deliverable: $e');
    }
  }

  // Get deliverables by status
  Future<ApiResponse> getDeliverablesByStatus(String status) async {
    try {
      final response = await getDeliverables();
      if (response.isSuccess && response.data != null) {
        final List<Deliverable> allDeliverables = response.data!['deliverables'] as List<Deliverable>;
        final List<Deliverable> filteredDeliverables = allDeliverables
            .where((deliverable) => deliverable.status.toLowerCase() == status.toLowerCase())
            .toList();
        
        return ApiResponse.success({'deliverables': filteredDeliverables}, 200);
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse.error('Error filtering deliverables: $e');
    }
  }

  // Get deliverables by priority
  Future<ApiResponse> getDeliverablesByPriority(String priority) async {
    try {
      final response = await getDeliverables();
      if (response.isSuccess && response.data != null) {
        final List<Deliverable> allDeliverables = response.data!['deliverables'] as List<Deliverable>;
        final List<Deliverable> filteredDeliverables = allDeliverables
            .where((deliverable) => deliverable.priority.toLowerCase() == priority.toLowerCase())
            .toList();
        
        return ApiResponse.success({'deliverables': filteredDeliverables}, 200);
      } else {
        return response;
      }
    } catch (e) {
      return ApiResponse.error('Error filtering deliverables: $e');
    }
  }
}
