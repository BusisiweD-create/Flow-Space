import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/approval_request.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';

class ApprovalService {
  final AuthService _authService;
  final String _baseUrl = 'http://localhost:8000/api/v1';

  ApprovalService(this._authService);

  // Get all approval requests
  Future<ApiResponse> getApprovalRequests({
    String? status,
    String? priority,
    String? category,
    String? deliverableId,
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final uri = Uri.parse('$_baseUrl/approvals').replace(
        queryParameters: {
          if (status != null) 'status': status,
          if (priority != null) 'priority': priority,
          if (category != null) 'category': category,
          if (deliverableId != null && deliverableId.isNotEmpty) 'deliverable_id': deliverableId,
        },
      );

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final list = data is List ? data : (data['data'] as List? ?? []);
        final requests = list.map((e) {
          final deliverable = e['deliverable'] as Map<String, dynamic>? ?? {};
          final requester = e['requester'] as Map<String, dynamic>? ?? {};
          final approver = e['approver'] as Map<String, dynamic>? ?? {};
          return ApprovalRequest(
            id: e['id']?.toString() ?? '',
            title: deliverable['title']?.toString() ?? 'Approval Request',
            description: e['comments']?.toString() ?? '',
            requestedBy: e['requested_by']?.toString() ?? requester['id']?.toString() ?? '',
            requestedByName: [requester['first_name'], requester['last_name']].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim().isNotEmpty
                ? [requester['first_name'], requester['last_name']].whereType<String>().join(' ').trim()
                : (requester['email']?.toString() ?? 'Unknown'),
            requestedAt: _parseDateTime(e['requested_at']) ?? DateTime.now(),
            status: _parseStatus(e['status']?.toString() ?? 'pending'),
            reviewedBy: e['approved_by']?.toString() ?? e['rejected_by']?.toString() ?? approver['id']?.toString(),
            reviewedByName: [approver['first_name'], approver['last_name']].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim().isNotEmpty
                ? [approver['first_name'], approver['last_name']].whereType<String>().join(' ').trim()
                : (approver['email']?.toString()),
            reviewedAt: _parseDateTime(e['approved_at'] ?? e['rejected_at']),
            reviewReason: e['comments']?.toString(),
            priority: e['priority']?.toString() ?? 'medium',
            category: e['category']?.toString() ?? '',
            deliverableId: deliverable['id']?.toString() ?? e['deliverable_id']?.toString(),
          );
        }).toList();
        return ApiResponse.success({'requests': requests}, response.statusCode);
      } else {
        return ApiResponse.error('Failed to fetch approval requests: ${response.statusCode}');
      }
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

      final uri = Uri.parse('$_baseUrl/approvals/$requestId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true || data['id'] != null) {
          final e = data['data'] ?? data;
          final deliverable = e['deliverable'] as Map<String, dynamic>? ?? {};
          final requester = e['requester'] as Map<String, dynamic>? ?? {};
          final approver = e['approver'] as Map<String, dynamic>? ?? {};
          final request = ApprovalRequest(
            id: e['id']?.toString() ?? '',
            title: deliverable['title']?.toString() ?? 'Approval Request',
            description: e['comments']?.toString() ?? '',
            requestedBy: e['requested_by']?.toString() ?? requester['id']?.toString() ?? '',
            requestedByName: [requester['first_name'], requester['last_name']].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim().isNotEmpty
                ? [requester['first_name'], requester['last_name']].whereType<String>().join(' ').trim()
                : (requester['email']?.toString() ?? 'Unknown'),
            requestedAt: _parseDateTime(e['requested_at']) ?? DateTime.now(),
            status: _parseStatus(e['status']?.toString() ?? 'pending'),
            reviewedBy: e['approved_by']?.toString() ?? e['rejected_by']?.toString() ?? approver['id']?.toString(),
            reviewedByName: [approver['first_name'], approver['last_name']].whereType<String>().where((s) => s.isNotEmpty).join(' ').trim().isNotEmpty
                ? [approver['first_name'], approver['last_name']].whereType<String>().join(' ').trim()
                : (approver['email']?.toString()),
            reviewedAt: _parseDateTime(e['approved_at'] ?? e['rejected_at']),
            reviewReason: e['comments']?.toString(),
            priority: e['priority']?.toString() ?? 'medium',
            category: e['category']?.toString() ?? '',
            deliverableId: deliverable['id']?.toString() ?? e['deliverable_id']?.toString(),
          );
          return ApiResponse.success({'request': request}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to fetch approval request');
        }
      } else {
        return ApiResponse.error('Failed to fetch approval request: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error fetching approval request: $e');
    }
  }

  // Approve an approval request
  Future<ApiResponse> approveRequest(String requestId, String reason) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final uri = Uri.parse('$_baseUrl/approvals/$requestId/approve');
      final approvedBy = _authService.currentUser?.id.toString() ?? '';
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'comments': reason, 'approved_by': approvedBy}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final request = ApprovalRequest.fromJson(data['data'] ?? {});
          return ApiResponse.success({'request': request}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to approve request');
        }
      } else {
        return ApiResponse.error('Failed to approve request: ${response.statusCode}');
      }
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

      final uri = Uri.parse('$_baseUrl/approvals/$requestId/reject');
      final approvedBy = _authService.currentUser?.id.toString() ?? '';
      final response = await http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'comments': reason, 'approved_by': approvedBy}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final request = ApprovalRequest.fromJson(data['data']);
          return ApiResponse.success({'request': request}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to reject request');
        }
      } else {
        return ApiResponse.error('Failed to reject request: ${response.statusCode}');
      }
    } catch (e) {
      return ApiResponse.error('Error rejecting request: $e');
    }
  }
  
  DateTime? _parseDateTime(dynamic input) {
    if (input == null) return null;
    if (input is DateTime) return input;
    if (input is String) {
      final s = input.trim();
      if (s.isEmpty) return null;
      try {
        return DateTime.parse(s);
      } catch (_) {
        final n = int.tryParse(s);
        if (n == null) return null;
        if (n > 100000000000) {
          return DateTime.fromMillisecondsSinceEpoch(n);
        } else if (n > 1000000000) {
          return DateTime.fromMillisecondsSinceEpoch(n * 1000);
        } else {
          return null;
        }
      }
    }
    if (input is num) {
      final n = input.toInt();
      if (n > 100000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n);
      } else if (n > 1000000000) {
        return DateTime.fromMillisecondsSinceEpoch(n * 1000);
      }
    }
    return null;
  }

  String _parseStatus(String status) {
    final s = status.toLowerCase().trim();
    switch (s) {
      case 'pending':
      case 'in_review':
      case 'awaiting':
      case 'waiting':
        return 'pending';
      case 'approved':
      case 'accept':
      case 'accepted':
      case 'confirm':
      case 'confirmed':
        return 'approved';
      case 'rejected':
      case 'reject':
      case 'denied':
      case 'deny':
        return 'rejected';
      default:
        return 'pending';
    }
  }
}
