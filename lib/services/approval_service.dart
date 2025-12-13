import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/approval_request.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ApprovalService {
  final AuthService _authService;
  final ApiClient _apiClient = ApiClient();
  io.Socket? _socket;
  final StreamController<List<ApprovalRequest>> _approvalRequestsController =
      StreamController<List<ApprovalRequest>>.broadcast();
  bool _realtimeInitialized = false;

  ApprovalService(this._authService);

  Stream<List<ApprovalRequest>> get approvalRequestsStream =>
      _approvalRequestsController.stream;

  void initRealtime() {
    if (_realtimeInitialized) return;
    _realtimeInitialized = true;

    _socket = io.io(
      'https://flow-space.onrender.com',
      io.OptionBuilder()
          .setTransports(['websocket'])
          .enableAutoConnect()
          .build(),
    );

    _socket!.onConnect((_) async {
      try {
        final response = await getApprovalRequests();
        if (response.isSuccess && response.data != null) {
          final list =
              response.data!['requests'].cast<ApprovalRequest>();
          _approvalRequestsController.add(list);
        }
      } catch (_) {}
    });

    _socket!.on('approval-request:changed', (data) async {
      try {
        final response = await getApprovalRequests();
        if (response.isSuccess && response.data != null) {
          final list =
              response.data!['requests'].cast<ApprovalRequest>();
          _approvalRequestsController.add(list);
        }
      } catch (_) {}
    });
  }

  void disposeRealtime() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    if (!_approvalRequestsController.isClosed) {
      _approvalRequestsController.close();
    }
  }

  // Get all approval requests
  Future<ApiResponse> getApprovalRequests({
    String? status,
    String? priority,
    String? category,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final queryParams = <String, String>{
        if (status != null) 'status': status,
        if (priority != null) 'priority': priority,
        if (category != null) 'category': category,
      };

      final response = await _apiClient.get('/approval-requests', queryParams: queryParams);

      if (response.isSuccess) {
        final List<dynamic> items = response.data is List ? response.data as List : [];
        final requests = items.map((json) => ApprovalRequest.fromJson(json as Map<String, dynamic>)).toList();
        return ApiResponse.success({'requests': requests}, response.statusCode);
      }
      return ApiResponse.error(response.error ?? 'Failed to fetch approval requests', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Error fetching approval requests: $e');
    }
  }

  // Get specific approval request
  Future<ApiResponse> getApprovalRequest(String requestId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final response = await _apiClient.get('/approval-requests/$requestId');

      if (response.isSuccess && response.data != null) {
        final request = ApprovalRequest.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success({'request': request}, response.statusCode);
      }
      return ApiResponse.error(response.error ?? 'Failed to fetch approval request', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Error fetching approval request: $e');
    }
  }

  // Create a new approval request (e.g. when a deliverable/report is submitted)
  Future<ApiResponse> createApprovalRequest({
    required String title,
    required String description,
    String priority = 'medium',
    String category = 'general',
    String? deliverableId,
    List<String>? evidenceLinks,
    List<String>? definitionOfDone,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final response = await _apiClient.post('/approval-requests', body: {
        'title': title,
        'description': description,
        'priority': priority,
        'category': category,
        'deliverable_id': deliverableId,
        'evidence_links': evidenceLinks,
        'definition_of_done': definitionOfDone,
      });

      if (response.isSuccess && response.data != null) {
        final request = ApprovalRequest.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success({'request': request}, response.statusCode);
      }
      return ApiResponse.error(response.error ?? 'Failed to create approval request', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Error creating approval request: $e');
    }
  }

  // Approve an approval request
  Future<ApiResponse> approveRequest(String requestId, String reason) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final response = await _apiClient.put('/approval-requests/$requestId', body: {
        'status': 'approved',
        'review_reason': reason,
      });

      if (response.isSuccess && response.data != null) {
        final request = ApprovalRequest.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success({'request': request}, response.statusCode);
      }
      return ApiResponse.error(response.error ?? 'Failed to approve request', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Error approving request: $e');
    }
  }

  // Reject an approval request
  Future<ApiResponse> rejectRequest(String requestId, String reason) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final response = await _apiClient.put('/approval-requests/$requestId', body: {
        'status': 'rejected',
        'review_reason': reason,
      });

      if (response.isSuccess && response.data != null) {
        final request = ApprovalRequest.fromJson(response.data as Map<String, dynamic>);
        return ApiResponse.success({'request': request}, response.statusCode);
      }
      return ApiResponse.error(response.error ?? 'Failed to reject request', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Error rejecting request: $e');
    }
  }

  // Get approvals by deliverable ID
  Future<ApiResponse> getApprovalsByDeliverableId(String deliverableId) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final response = await _apiClient.get('/approval-requests', queryParams: {
        'deliverable_id': deliverableId,
      });

      if (response.isSuccess) {
        final List<dynamic> items = response.data is List ? response.data as List : [];
        final requests = items.map((json) => ApprovalRequest.fromJson(json as Map<String, dynamic>)).toList();
        return ApiResponse.success({'requests': requests}, response.statusCode);
      }
      return ApiResponse.error(response.error ?? 'Failed to fetch approvals', response.statusCode);
    } catch (e) {
      return ApiResponse.error('Error fetching approvals: $e');
    }
  }
}
