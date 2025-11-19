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
  }) async {
    try {
      final token = _authService.accessToken;
      if (token == null) {
        return ApiResponse.error('No authentication token available');
      }

      final uri = Uri.parse('$_baseUrl/approval-requests').replace(
        queryParameters: {
          if (status != null) 'status': status,
          if (priority != null) 'priority': priority,
          if (category != null) 'category': category,
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
        if (data['success'] == true) {
          final requests = (data['data'] as List)
              .map((json) => ApprovalRequest.fromJson(json))
              .toList();
          return ApiResponse.success({'requests': requests}, response.statusCode);
        } else {
          return ApiResponse.error(data['error'] ?? 'Failed to fetch approval requests');
        }
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

      final uri = Uri.parse('$_baseUrl/approval-requests/$requestId');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final request = ApprovalRequest.fromJson(data['data']);
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

      final uri = Uri.parse('$_baseUrl/approval-requests/$requestId/approve');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          final request = ApprovalRequest.fromJson(data['data']);
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

      final uri = Uri.parse('$_baseUrl/approval-requests/$requestId/reject');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'reason': reason}),
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
}
