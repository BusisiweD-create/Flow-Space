// ignore_for_file: avoid_print

import 'package:flutter_test/flutter_test.dart';
import 'package:khono/models/client_approval_request.dart';
import 'package:khono/providers/client_approval_provider.dart';

void main() {
  group('Client Approval Workflow Test', () {
    late ClientApprovalNotifier approvalNotifier;

    setUp(() {
      // Create a new instance of the notifier for each test
      approvalNotifier = ClientApprovalNotifier();
    });

    test('Test 1: Load initial approval requests', () async {
      // Act
      await approvalNotifier.loadApprovalRequests();

      // Assert
      expect(approvalNotifier.state.approvalRequests.length, 2); // Mock data has 2 requests
      expect(approvalNotifier.state.isLoading, false);
    });

    test('Test 2: Send request for approval', () async {
      // Act
      await approvalNotifier.sendForApproval(
        deliverableId: 'deliverable_3',
        deliverableTitle: 'Test Deliverable',
        clientId: 'client_3',
        clientName: 'Test Client',
      );

      // Assert
      expect(approvalNotifier.state.approvalRequests.length, 1);
      final newRequest = approvalNotifier.state.approvalRequests.last;
      expect(newRequest.deliverableId, 'deliverable_3');
      expect(newRequest.deliverableTitle, 'Test Deliverable');
      expect(newRequest.clientId, 'client_3');
      expect(newRequest.clientName, 'Test Client');
      expect(newRequest.status, ClientApprovalStatus.pending);
    });

    test('Test 3: Get pending approvals', () async {
      // Arrange - load mock data first
      await approvalNotifier.loadApprovalRequests();

      // Act
      final result = approvalNotifier.getPendingApprovals();

      // Assert
      expect(result.length, 2); // Both mock requests are pending
      expect(result.every((r) => r.status == ClientApprovalStatus.pending), isTrue);
    });

    test('Test 4: Send reminder for approval', () async {
      // Arrange - load mock data first
      await approvalNotifier.loadApprovalRequests();
      final requestId = approvalNotifier.state.approvalRequests.first.id;

      // Act
      await approvalNotifier.sendReminder(requestId);

      // Assert - check that reminder was sent
      final updatedRequest = approvalNotifier.state.approvalRequests
          .firstWhere((request) => request.id == requestId);
      expect(updatedRequest.status, ClientApprovalStatus.reminderSent);
      expect(updatedRequest.reminderSentAt.length, 1);
    });

    test('Test 5: Approve request', () async {
      // Arrange - load mock data first
      await approvalNotifier.loadApprovalRequests();
      final requestId = approvalNotifier.state.approvalRequests.first.id;

      // Act
      await approvalNotifier.approveRequest(requestId);

      // Assert
      final approvedRequest = approvalNotifier.state.approvalRequests
          .firstWhere((request) => request.id == requestId);
      expect(approvedRequest.status, ClientApprovalStatus.approved);
      expect(approvedRequest.approvedAt, isNotNull);
      expect(approvalNotifier.getPendingApprovals().length, 1); // One remaining pending
    });

    test('Test 6: Reject request', () async {
      // Arrange - load mock data first
      await approvalNotifier.loadApprovalRequests();
      final requestId = approvalNotifier.state.approvalRequests.first.id;

      // Act
      await approvalNotifier.rejectRequest(requestId, comments: 'Not satisfied with the deliverable');

      // Assert
      final rejectedRequest = approvalNotifier.state.approvalRequests
          .firstWhere((request) => request.id == requestId);
      expect(rejectedRequest.status, ClientApprovalStatus.rejected);
      expect(rejectedRequest.rejectedAt, isNotNull);
      expect(rejectedRequest.comments, 'Not satisfied with the deliverable');
      expect(approvalNotifier.getPendingApprovals().length, 1); // One remaining pending
    });

    test('Test 7: Get overdue approvals', () async {
      // Arrange - load mock data first
      await approvalNotifier.loadApprovalRequests();

      // Act
      final result = approvalNotifier.getOverdueApprovals();

      // Assert - mock data has one overdue request (due in 2 days from 5 days ago)
      expect(result.length, 1);
      expect(result.first.clientName, 'Acme Corp');
    });

    test('Test 8: Get approvals needing reminder', () async {
      // Arrange - load mock data first
      await approvalNotifier.loadApprovalRequests();

      // Act
      final result = approvalNotifier.getApprovalsNeedingReminder();

      // Assert - mock data has one request needing reminder (due in 2 days)
      expect(result.length, 1);
      expect(result.first.clientName, 'Acme Corp');
    });
  });
}