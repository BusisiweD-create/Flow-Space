import '../models/user.dart';
import '../models/user_role.dart';
import '../models/deliverable.dart';
import '../models/sprint_metrics.dart';
import '../models/sign_off_report.dart';
import 'api_client.dart';
import 'smtp_email_service.dart';

class MockBackend {
  static final MockBackend _instance = MockBackend._internal();
  factory MockBackend() => _instance;
  MockBackend._internal();

  // Mock data storage
  final List<User> _users = [];
  final List<Deliverable> _deliverables = [];
  final List<SprintMetrics> _sprintMetrics = [];
  final List<SignOffReport> _signOffReports = [];

  // Initialize with mock data
  void initialize() {
    _initializeMockUsers();
    _initializeMockDeliverables();
    _initializeMockSprintMetrics();
    _initializeMockSignOffReports();
  }

  void _initializeMockUsers() {
    _users.addAll([
      User(
        id: '1',
        email: 'team@example.com',
        name: 'John Developer',
        role: UserRole.teamMember,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        isActive: true,
      ),
      User(
        id: '2',
        email: 'lead@example.com',
        name: 'Sarah Project Manager',
        role: UserRole.deliveryLead,
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
        isActive: true,
      ),
      User(
        id: '3',
        email: 'client@example.com',
        name: 'Mike Client',
        role: UserRole.clientReviewer,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        isActive: true,
      ),
      User(
        id: '4',
        email: 'admin@example.com',
        name: 'Admin User',
        role: UserRole.systemAdmin,
        createdAt: DateTime.now().subtract(const Duration(days: 90)),
        isActive: true,
      ),
    ]);
  }

  void _initializeMockDeliverables() {
    _deliverables.addAll([
      Deliverable(
        id: '1',
        title: 'User Authentication System',
        description: 'Complete user login, registration, and role-based access control',
        status: DeliverableStatus.submitted,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        dueDate: DateTime.now().add(const Duration(days: 2)),
        sprintIds: ['sprint-1', 'sprint-2'],
        definitionOfDone: [
          'All unit tests pass with >90% coverage',
          'Code review completed by senior developer',
          'Security audit passed with no critical issues',
        ],
        evidenceLinks: [
          'https://demo.example.com/auth',
          'https://github.com/company/auth-system',
        ],
        submittedBy: 'John Developer',
        submittedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      Deliverable(
        id: '2',
        title: 'Payment Integration',
        description: 'Payment gateway integration with multiple providers',
        status: DeliverableStatus.draft,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        dueDate: DateTime.now().add(const Duration(days: 7)),
        sprintIds: ['sprint-3'],
        definitionOfDone: [
          'Payment processing implemented',
          'Error handling and retry logic',
          'Security compliance verified',
        ],
        evidenceLinks: [
          'https://demo.example.com/payments',
        ],
        submittedBy: 'Sarah Project Manager',
      ),
    ]);
  }

  void _initializeMockSprintMetrics() {
    _sprintMetrics.addAll([
      SprintMetrics(
        id: '1',
        sprintId: 'sprint-1',
        committedPoints: 20,
        completedPoints: 18,
        carriedOverPoints: 2,
        testPassRate: 95.5,
        defectsOpened: 3,
        defectsClosed: 3,
        criticalDefects: 0,
        highDefects: 1,
        mediumDefects: 1,
        lowDefects: 1,
        codeReviewCompletion: 100.0,
        documentationStatus: 85.0,
        risks: 'Initial authentication complexity',
        mitigations: 'Extended testing phase',
        scopeChanges: 'Added MFA requirement',
        uatNotes: 'Client feedback incorporated',
        recordedAt: DateTime.now().subtract(const Duration(days: 7)),
        recordedBy: 'Sprint Lead',
      ),
    ]);
  }

  void _initializeMockSignOffReports() {
    _signOffReports.addAll([
      SignOffReport(
        id: '1',
        deliverableId: '1',
        reportTitle: 'Sign-Off Report: User Authentication System',
        reportContent: 'Comprehensive report for authentication system...',
        sprintIds: ['sprint-1', 'sprint-2'],
        status: ReportStatus.approved,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        createdBy: 'John Developer',
        submittedAt: DateTime.now().subtract(const Duration(days: 4)),
        submittedBy: 'Sarah Project Manager',
        approvedAt: DateTime.now().subtract(const Duration(days: 2)),
        approvedBy: 'Mike Client',
        digitalSignature: 'sig_123456789',
      ),
    ]);
  }

  // Authentication methods
  ApiResponse login(String email, String password) {
    // Simulate network delay
    Future.delayed(const Duration(milliseconds: 500));

    final user = _users.firstWhere(
      (u) => u.email == email,
      orElse: () => throw Exception('User not found'),
    );

    if (password != 'password123') {
      return ApiResponse.error('Invalid password', 401);
    }

    return ApiResponse.success({
      'user': user.toJson(),
      'access_token': 'mock_access_token_${user.id}',
      'refresh_token': 'mock_refresh_token_${user.id}',
      'expires_in': 3600,
    }, 200,);
  }

  ApiResponse register(String email, String password, String name, String role) {
    // Check if user already exists
    if (_users.any((u) => u.email == email)) {
      return ApiResponse.error('User already exists', 409);
    }

    final newUser = User(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      email: email,
      name: name,
      role: UserRole.values.firstWhere((r) => r.name == role),
      createdAt: DateTime.now(),
      isActive: true,
      emailVerified: false, // New users need email verification
    );

    _users.add(newUser);

    return ApiResponse.success({
      'user': newUser.toJson(),
      'access_token': 'mock_access_token_${newUser.id}',
      'refresh_token': 'mock_refresh_token_${newUser.id}',
      'expires_in': 3600,
    }, 201,);
  }

  ApiResponse getCurrentUser(String token) {
    final userId = token.replaceAll('mock_access_token_', '');
    final user = _users.firstWhere(
      (u) => u.id == userId,
      orElse: () => throw Exception('User not found'),
    );

    return ApiResponse.success({'user': user.toJson()}, 200);
  }

  ApiResponse logout() {
    return ApiResponse.success({'message': 'Logged out successfully'}, 200);
  }

  // Deliverable methods
  ApiResponse getDeliverables({int page = 1, int limit = 20, String? status, String? search}) {
    var filteredDeliverables = _deliverables;

    if (status != null && status.isNotEmpty) {
      final statusEnum = DeliverableStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => DeliverableStatus.draft,
      );
      filteredDeliverables = filteredDeliverables.where((d) => d.status == statusEnum).toList();
    }

    if (search != null && search.isNotEmpty) {
      filteredDeliverables = filteredDeliverables.where((d) =>
          d.title.toLowerCase().contains(search.toLowerCase()) ||
          d.description.toLowerCase().contains(search.toLowerCase()),
      ).toList();
    }

    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, filteredDeliverables.length);
    final paginatedDeliverables = filteredDeliverables.sublist(startIndex, endIndex);

    return ApiResponse.success({
      'data': paginatedDeliverables.map((d) => d.toJson()).toList(),
      'pagination': {
        'page': page,
        'limit': limit,
        'total': filteredDeliverables.length,
        'pages': (filteredDeliverables.length / limit).ceil(),
      },
    }, 200,);
  }

  ApiResponse createDeliverable(Map<String, dynamic> data) {
    final newDeliverable = Deliverable(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      status: DeliverableStatus.draft,
      createdAt: DateTime.now(),
      dueDate: DateTime.parse(data['dueDate'] ?? DateTime.now().add(const Duration(days: 7)).toIso8601String()),
      sprintIds: List<String>.from(data['sprintIds'] ?? []),
      definitionOfDone: List<String>.from(data['definitionOfDone'] ?? []),
      evidenceLinks: List<String>.from(data['evidenceLinks'] ?? []),
      submittedBy: data['submittedBy'] ?? 'Current User',
    );

    _deliverables.add(newDeliverable);

    return ApiResponse.success({'deliverable': newDeliverable.toJson()}, 201);
  }

  // Sprint metrics methods
  ApiResponse getSprintMetrics(String sprintId) {
    final metrics = _sprintMetrics.where((m) => m.sprintId == sprintId).toList();
    return ApiResponse.success({
      'data': metrics.map((m) => m.toJson()).toList(),
    }, 200,);
  }

  ApiResponse createSprintMetrics(String sprintId, Map<String, dynamic> data) {
    final newMetrics = SprintMetrics(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      sprintId: sprintId,
      committedPoints: data['committedPoints'] ?? 0,
      completedPoints: data['completedPoints'] ?? 0,
      carriedOverPoints: data['carriedOverPoints'] ?? 0,
      testPassRate: data['testPassRate'] ?? 0.0,
      defectsOpened: data['defectsOpened'] ?? 0,
      defectsClosed: data['defectsClosed'] ?? 0,
      criticalDefects: data['criticalDefects'] ?? 0,
      highDefects: data['highDefects'] ?? 0,
      mediumDefects: data['mediumDefects'] ?? 0,
      lowDefects: data['lowDefects'] ?? 0,
      codeReviewCompletion: data['codeReviewCompletion'] ?? 0.0,
      documentationStatus: data['documentationStatus'] ?? 0.0,
      risks: data['risks'],
      mitigations: data['mitigations'],
      scopeChanges: data['scopeChanges'],
      uatNotes: data['uatNotes'],
      recordedAt: DateTime.now(),
      recordedBy: data['recordedBy'] ?? 'Current User',
    );

    _sprintMetrics.add(newMetrics);

    return ApiResponse.success({'metrics': newMetrics.toJson()}, 201);
  }

  // Sign-off report methods
  ApiResponse getSignOffReports({int page = 1, int limit = 20, String? status, String? search}) {
    var filteredReports = _signOffReports;

    if (status != null && status.isNotEmpty) {
      final statusEnum = ReportStatus.values.firstWhere(
        (s) => s.name == status,
        orElse: () => ReportStatus.draft,
      );
      filteredReports = filteredReports.where((r) => r.status == statusEnum).toList();
    }

    if (search != null && search.isNotEmpty) {
      filteredReports = filteredReports.where((r) =>
          r.reportTitle.toLowerCase().contains(search.toLowerCase()) ||
          r.createdBy.toLowerCase().contains(search.toLowerCase()),
      ).toList();
    }

    final startIndex = (page - 1) * limit;
    final endIndex = (startIndex + limit).clamp(0, filteredReports.length);
    final paginatedReports = filteredReports.sublist(startIndex, endIndex);

    return ApiResponse.success({
      'data': paginatedReports.map((r) => r.toJson()).toList(),
      'pagination': {
        'page': page,
        'limit': limit,
        'total': filteredReports.length,
        'pages': (filteredReports.length / limit).ceil(),
      },
    }, 200,);
  }

  ApiResponse createSignOffReport(Map<String, dynamic> data) {
    final newReport = SignOffReport(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      deliverableId: data['deliverableId'] ?? '',
      reportTitle: data['reportTitle'] ?? '',
      reportContent: data['reportContent'] ?? '',
      sprintIds: List<String>.from(data['sprintIds'] ?? []),
      status: ReportStatus.draft,
      createdAt: DateTime.now(),
      createdBy: data['createdBy'] ?? 'Current User',
    );

    _signOffReports.add(newReport);

    return ApiResponse.success({'report': newReport.toJson()}, 201);
  }

  // Dashboard data
  ApiResponse getDashboardData() {
    return ApiResponse.success({
      'total_deliverables': _deliverables.length,
      'completed_deliverables': _deliverables.where((d) => d.status == DeliverableStatus.approved).length,
      'pending_reviews': _signOffReports.where((r) => r.status == ReportStatus.submitted).length,
      'overdue_deliverables': _deliverables.where((d) => d.isOverdue).length,
      'recent_activity': [
        {
          'type': 'deliverable_created',
          'title': 'New deliverable created',
          'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        },
        {
          'type': 'report_submitted',
          'title': 'Sign-off report submitted',
          'timestamp': DateTime.now().subtract(const Duration(hours: 4)).toIso8601String(),
        },
      ],
    }, 200,);
  }

  // Health check
  ApiResponse getHealthCheck() {
    return ApiResponse.success({
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    }, 200,);
  }

  // Email verification endpoints
  ApiResponse resendVerificationEmail(String email) {
    // Use real SMTP email service
    final emailService = SmtpEmailService();
    final verificationCode = emailService.generateVerificationCode();
    
    // Send actual email via SMTP
    emailService.sendVerificationEmail(
      toEmail: email,
      userName: 'User', // In real implementation, get from user data
      verificationCode: verificationCode,
    );
    
    return ApiResponse.success({
      'message': 'Verification email sent successfully',
      'email': email,
      'sent_at': DateTime.now().toIso8601String(),
    }, 200,);
  }

  ApiResponse verifyEmail(String email, String verificationCode) {
    // Use real SMTP email service for validation
    final emailService = SmtpEmailService();
    
    if (emailService.validateVerificationCode(
      email: email,
      inputCode: verificationCode,
    )) {
      // Update user verification status
      final userIndex = _users.indexWhere((user) => user.email == email);
      if (userIndex != -1) {
        _users[userIndex] = _users[userIndex].copyWith(
          emailVerified: true,
          emailVerifiedAt: DateTime.now(),
        );
      }
      
      return ApiResponse.success({
        'message': 'Email verified successfully',
        'email': email,
        'verified_at': DateTime.now().toIso8601String(),
      }, 200,);
    } else {
      return ApiResponse.error('Invalid or expired verification code', 400,);
    }
  }

  ApiResponse checkEmailVerificationStatus(String email) {
    final user = _users.firstWhere(
      (user) => user.email == email,
      orElse: () => throw Exception('User not found'),
    );
    
    return ApiResponse.success({
      'email': email,
      'is_verified': user.emailVerified,
      'verified_at': user.emailVerifiedAt?.toIso8601String(),
    }, 200,);
  }
}
