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
    return Deliverable(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      definitionOfDone: json['definition_of_done'],
      priority: json['priority'],
      status: json['status'],
      dueDate: json['due_date'] != null ? DateTime.parse(json['due_date']) : null,
      createdBy: json['created_by'],
      assignedTo: json['assigned_to'],
      sprintId: json['sprint_id'],
      createdByName: json['created_by_name'],
      assignedToName: json['assigned_to_name'],
      sprintName: json['sprint_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
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
        final List<dynamic> deliverablesJson = response.data!['data'] as List<dynamic>;
        final List<Deliverable> deliverables = deliverablesJson
            .map((json) => Deliverable.fromJson(json))
            .toList();
        
        return ApiResponse.success({'deliverables': deliverables}, response.statusCode);
      } else {
        return ApiResponse.error(response.error ?? 'Failed to fetch deliverables');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching deliverables: $e');
    }
  }

  // Create a new deliverable
  Future<ApiResponse> createDeliverable({
    required String title,
    String? description,
    String? definitionOfDone,
    String priority = 'Medium',
    String status = 'Draft',
    DateTime? dueDate,
    String? assignedTo,
    String? sprintId,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No access token available');
      }

      final body = {
        'title': title,
        'description': description,
        'definition_of_done': definitionOfDone,
        'priority': priority,
        'status': status,
        'due_date': dueDate?.toIso8601String(),
        'assigned_to': assignedTo,
        'sprint_id': sprintId,
      };

      final response = await _apiClient.post('/deliverables', body: body);
      
      if (response.isSuccess && response.data != null) {
        final deliverable = Deliverable.fromJson(response.data!['data']);
        return ApiResponse.success({'deliverable': deliverable}, response.statusCode);
      } else {
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
        final deliverable = Deliverable.fromJson(response.data!['data']);
        return ApiResponse.success({'deliverable': deliverable}, response.statusCode);
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
