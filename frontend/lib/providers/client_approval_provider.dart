import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/client_approval_request.dart';
import '../services/api_service.dart';

class ClientApprovalState {
  final List<ClientApprovalRequest> approvalRequests;
  final bool isLoading;
  final String? error;

  ClientApprovalState({
    required this.approvalRequests,
    this.isLoading = false,
    this.error,
  });

  ClientApprovalState copyWith({
    List<ClientApprovalRequest>? approvalRequests,
    bool? isLoading,
    String? error,
  }) {
    return ClientApprovalState(
      approvalRequests: approvalRequests ?? this.approvalRequests,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ClientApprovalNotifier extends Notifier<ClientApprovalState> {
  @override
  ClientApprovalState build() {
    return ClientApprovalState(approvalRequests: []);
  }

  Future<void> loadApprovalRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final items = await ApiService.getApprovalRequests(limit: 100);
      final requests = items.map((json) {
        final statusStr = (json['status'] ?? 'pending').toString();
        final status = ClientApprovalStatus.values.firstWhere(
          (e) => e.name.toLowerCase() == statusStr.toLowerCase(),
          orElse: () => ClientApprovalStatus.pending,
        );
        DateTime parseDate(dynamic v) {
          if (v == null) return DateTime.now();
          return DateTime.tryParse(v.toString()) ?? DateTime.now();
        }
        List<DateTime> parseDates(dynamic list) {
          final l = (list as List?) ?? [];
          return l.map((e) => DateTime.tryParse(e.toString()) ?? DateTime.now()).toList();
        }
        return ClientApprovalRequest(
          id: (json['id'] ?? '').toString(),
          deliverableId: json['deliverable_id'] ?? json['deliverableId'] ?? '',
          deliverableTitle: json['deliverable_title'] ?? json['deliverableTitle'] ?? '',
          clientId: json['client_id'] ?? json['clientId'] ?? '',
          clientName: json['client_name'] ?? json['clientName'] ?? '',
          deliveryManagerId: json['requested_by'] ?? json['deliveryManagerId'] ?? '',
          deliveryManagerName: json['delivery_manager_name'] ?? json['deliveryManagerName'] ?? '',
          requestedAt: parseDate(json['requested_at'] ?? json['requestedAt']),
          approvedAt: json['approved_at'] != null ? parseDate(json['approved_at']) : null,
          rejectedAt: json['rejected_at'] != null ? parseDate(json['rejected_at']) : null,
          status: status,
          comments: json['comment'] ?? json['comments'],
          reminderSentAt: parseDates(json['reminder_sent_at'] ?? json['reminderSentAt']),
          dueDate: json['due_date'] != null ? parseDate(json['due_date']) : null,
        );
      }).toList();
      state = state.copyWith(approvalRequests: requests, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to load approval requests: $e');
    }
  }

  Future<void> sendForApproval({
    required String deliverableId,
    required String deliverableTitle,
    required String clientId,
    required String clientName,
    DateTime? dueDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final requesterId = ApiService.currentUserId ?? '';
      final requesterName = await ApiService.currentUserFullName ?? '';
      final reqBody = {
        'deliverable_id': deliverableId,
        'client_id': clientId,
        'deliverable_title': deliverableTitle,
        'client_name': clientName,
        'requested_by': requesterId,
        'requested_by_name': requesterName,
        if (dueDate != null) 'due_date': dueDate.toIso8601String(),
      };
      final created = await ApiService.createApprovalRequest(reqBody);
      if (created != null) {
        await loadApprovalRequests();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send for approval: $e',
      );
    }
  }

  Future<void> approveRequest(String requestId, {String? comments}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final ok = await ApiService.approveApprovalRequest(requestId, comment: comments);
      if (ok) {
        await loadApprovalRequests();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to approve request: $e',
      );
    }
  }

  Future<void> rejectRequest(String requestId, {required String comments}) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final ok = await ApiService.rejectApprovalRequest(requestId, comment: comments);
      if (ok) {
        await loadApprovalRequests();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to reject request: $e',
      );
    }
  }

  Future<void> sendReminder(String requestId) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final ok = await ApiService.sendApprovalReminder(requestId);
      if (ok) {
        await loadApprovalRequests();
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reminder: $e',
      );
    }
  }

  List<ClientApprovalRequest> getPendingApprovals() {
    return state.approvalRequests
        .where((request) => request.status == ClientApprovalStatus.pending)
        .toList();
  }

  List<ClientApprovalRequest> getOverdueApprovals() {
    return state.approvalRequests
        .where((request) => request.status == ClientApprovalStatus.pending && 
            request.dueDate != null && 
            request.dueDate!.isBefore(DateTime.now()),
        )
        .toList();
  }

  List<ClientApprovalRequest> getApprovalsNeedingReminder() {
    return state.approvalRequests
        .where((request) => request.status == ClientApprovalStatus.pending && 
            request.dueDate != null && 
            request.dueDate!.difference(DateTime.now()).inDays <= 1,
        )
        .toList();
  }
}

final clientApprovalProvider = NotifierProvider<ClientApprovalNotifier, ClientApprovalState>(
  () => ClientApprovalNotifier(),
);