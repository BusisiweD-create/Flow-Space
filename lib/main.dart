import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/backend_api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/deliverable_setup_screen.dart';
import 'screens/enhanced_deliverable_setup_screen.dart';
import 'screens/sprint_console_screen.dart';
import 'screens/sprint_metrics_screen.dart';
import 'screens/report_builder_screen.dart';
import 'screens/report_editor_screen.dart';
import 'screens/client_review_screen.dart';
import 'models/sign_off_report.dart';
import 'models/deliverable.dart';
import 'screens/enhanced_client_review_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/report_repository_screen.dart';
// Approvals unified: use ApprovalRequestsScreen
import 'screens/approval_requests_screen.dart';
import 'screens/repository_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/smtp_config_screen.dart';
import 'screens/role_dashboard_screen.dart';
import 'screens/role_management_screen.dart';
// import 'screens/user_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sprint_board_screen.dart';
import 'screens/system_metrics_screen.dart';
import 'screens/system_health_screen.dart';
import 'screens/audit_logs_screen.dart';
// Removed imports for non-existent screens to resolve analyzer errors
import 'widgets/sidebar_scaffold.dart';
//
import 'widgets/role_guard.dart';
import 'theme/flownet_theme.dart';
import 'screens/deadlines_screen.dart';
import 'screens/skill_assessment_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  try {
    // Initialize API Services
    await BackendApiService().initialize();
    await AuthService().initialize();
    // RealAuthService removed - using AuthService instead
    
    // Test SMTP connection on startup (optional)
    // Uncomment the lines below to test SMTP on app startup
    // final emailService = SmtpEmailService();
    // final isConnected = await emailService.testSmtpConnection();
    // debugPrint('SMTP Connection: ${isConnected ? "✅ Success" : "❌ Failed"}');
  } catch (e) {
    debugPrint('API Service initialization failed: $e');
    // Continue without API service for now
  }

  runApp(const ProviderScope(child: KhonoApp()));
}

class KhonoApp extends StatelessWidget {
  const KhonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Flownet Workspaces - Project Management Hub',
      theme: FlownetTheme.darkTheme, // Dark mode as default
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const WelcomeScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/verify-email',
      builder: (context, state) {
        final extra = state.extra;
        final emailFromExtra = extra is Map<String, dynamic> ? (extra['email'] as String?) : null;
        final emailFromQuery = state.uri.queryParameters['email'];
        final codeFromQuery = state.uri.queryParameters['code'];
        return EmailVerificationScreen(
          email: emailFromExtra ?? emailFromQuery ?? '',
          verificationCode: codeFromQuery,
        );
      },
    ),
    GoRoute(
      path: '/email-verification',
      builder: (context, state) {
        final extra = state.extra;
        final emailFromExtra = extra is Map<String, dynamic> ? (extra['email'] as String?) : null;
        final emailFromQuery = state.uri.queryParameters['email'];
        final codeFromQuery = state.uri.queryParameters['code'];
        return EmailVerificationScreen(
          email: emailFromExtra ?? emailFromQuery ?? '',
          verificationCode: codeFromQuery,
        );
      },
    ),
    GoRoute(
      path: '/verify-email/:code',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        final emailFromQuery = state.uri.queryParameters['email'] ?? '';
        return EmailVerificationScreen(
          email: emailFromQuery,
          verificationCode: code,
        );
      },
    ),
    GoRoute(
      path: '/email-verification/:code',
      builder: (context, state) {
        final code = state.pathParameters['code']!;
        final emailFromQuery = state.uri.queryParameters['email'] ?? '';
        return EmailVerificationScreen(
          email: emailFromQuery,
          verificationCode: code,
        );
      },
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const RouteGuard(
        route: '/dashboard',
        child: SidebarScaffold(
          child: RoleDashboardScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/deliverable-setup',
      builder: (context, state) => const RouteGuard(
        route: '/deliverable-setup',
        child: SidebarScaffold(
          child: DeliverableSetupScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/enhanced-deliverable-setup',
      builder: (context, state) => const RouteGuard(
        route: '/enhanced-deliverable-setup',
        child: SidebarScaffold(
          child: EnhancedDeliverableSetupScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/sprint-metrics/:sprintId',
      builder: (context, state) {
        final sprintId = state.pathParameters['sprintId']!;
        return RouteGuard(
          route: '/sprint-metrics',
          child: SidebarScaffold(
            child: SprintMetricsScreen(sprintId: sprintId),
          ),
        );
      },
    ),
    GoRoute(
      path: '/report-builder/:deliverableId',
      builder: (context, state) {
        final deliverableId = state.pathParameters['deliverableId']!;
        return RouteGuard(
          route: '/report-builder',
          child: SidebarScaffold(
            child: ReportBuilderScreen(deliverableId: deliverableId),
          ),
        );
      },
    ),
    GoRoute(
      path: '/report-editor/:deliverableId',
      builder: (context, state) {
        final deliverableId = state.pathParameters['deliverableId']!;
        return RouteGuard(
          route: '/report-editor',
          child: SidebarScaffold(
            child: ReportEditorScreen(deliverableId: deliverableId),
          ),
        );
      },
    ),
    GoRoute(
      path: '/client-review/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        final extra = state.extra;
        SignOffReport? initialReport;
        Deliverable? initialDeliverable;
        if (extra is Map) {
          try { initialReport = extra['report'] as SignOffReport?; } catch (_) {}
          try { initialDeliverable = extra['deliverable'] as Deliverable?; } catch (_) {}
        }
        return RouteGuard(
          route: '/client-review',
          child: SidebarScaffold(
            child: ClientReviewScreen(
              reportId: reportId,
              initialReport: initialReport,
              initialDeliverable: initialDeliverable,
            ),
          ),
        );
      },
    ),
    GoRoute(
      path: '/enhanced-client-review/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return RouteGuard(
          route: '/enhanced-client-review',
          child: SidebarScaffold(
            child: EnhancedClientReviewScreen(reportId: reportId),
          ),
        );
      },
    ),
    GoRoute(
      path: '/notification-center',
      builder: (context, state) => const RouteGuard(
        route: '/notification-center',
        child: SidebarScaffold(
          child: NotificationCenterScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/report-repository',
      builder: (context, state) => const RouteGuard(
        route: '/report-repository',
        child: SidebarScaffold(
          child: ReportRepositoryScreen(),
        ),
      ),
    ),
    
    GoRoute(
      path: '/deadlines',
      builder: (context, state) => const RouteGuard(
        route: '/deadlines',
        child: SidebarScaffold(
          child: DeadlinesScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/sprint-console',
            builder: (context, state) => RouteGuard(
              route: '/sprint-console',
              child: SidebarScaffold(
                child: SprintConsoleScreen(
                  initialProjectKey: state.uri.queryParameters['projectKey'],
                ),
              ),
            ),
    ),
    GoRoute(
      path: '/sprint-board/:sprintId',
      builder: (context, state) {
        final sprintId = state.pathParameters['sprintId']!;
        final sprintName = state.uri.queryParameters['name'] ?? 'Sprint Board';
        return RouteGuard(
          route: '/sprint-board',
          child: SidebarScaffold(
            child: SprintBoardScreen(
              sprintId: sprintId,
              sprintName: sprintName,
            ),
          ),
        );
      },
    ),
  GoRoute(
    path: '/approvals',
    builder: (context, state) => const RouteGuard(
      route: '/approval-requests',
      child: SidebarScaffold(
        child: ApprovalRequestsScreen(),
      ),
    ),
  ),
  GoRoute(
    path: '/approval-requests',
    builder: (context, state) => const RouteGuard(
      route: '/approval-requests',
      child: SidebarScaffold(
        child: ApprovalRequestsScreen(),
      ),
    ),
  ),
    GoRoute(
      path: '/repository',
      builder: (context, state) => const RouteGuard(
        route: '/repository',
        child: SidebarScaffold(
          child: RepositoryScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/repository/:projectKey',
      builder: (context, state) => RouteGuard(
        route: '/repository',
        child: SidebarScaffold(
          child: RepositoryScreen(projectKey: state.pathParameters['projectKey']),
        ),
      ),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const RouteGuard(
        route: '/notifications',
        child: SidebarScaffold(
          child: NotificationsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/smtp-config',
      builder: (context, state) => const SmtpConfigScreen(),
    ),
    GoRoute(
      path: '/role-management',
      builder: (context, state) => const RouteGuard(
        route: '/role-management',
        child: SidebarScaffold(
          child: RoleManagementScreen(),
        ),
      ),
    ),
    // Removed redundant user-management route; role-management covers it
    
    GoRoute(
      path: '/profile',
      builder: (context, state) => const RouteGuard(
        route: '/profile',
        child: SidebarScaffold(
          child: ProfileScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const RouteGuard(
        route: '/settings',
        child: SidebarScaffold(
          child: SettingsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/system-metrics',
      builder: (context, state) => const RouteGuard(
        route: '/system-metrics',
        child: SidebarScaffold(
          child: SystemMetricsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/system-health',
      builder: (context, state) => const RouteGuard(
        route: '/system-health',
        child: SidebarScaffold(
          child: SystemHealthScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/audit-logs',
      builder: (context, state) => const RouteGuard(
        route: '/audit-logs',
        child: SidebarScaffold(
          child: AuditLogsScreen(),
        ),
      ),
    ),
    GoRoute(
      path: '/assessment/:skill',
      builder: (context, state) => RouteGuard(
        route: '/skill-assessment',
        child: SidebarScaffold(
          child: SkillAssessmentScreen(selectedSkill: state.pathParameters['skill']),
        ),
      ),
    ),
    GoRoute(
      path: '/account',
      redirect: (context, state) => '/profile',
    ),
  ],
);
