import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_core/firebase_core.dart';
import 'widgets/app_container.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/backend_api_service.dart';
import 'screens/signoff_hub_welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/enhanced_deliverable_setup_screen.dart';
import 'screens/sprint_console_screen.dart';
import 'screens/sprint_metrics_screen.dart';
import 'screens/report_builder_screen.dart';
import 'screens/client_review_screen.dart';
import 'screens/enhanced_client_review_screen.dart';
import 'screens/notification_center_screen.dart';
import 'screens/report_repository_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/repository_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/smtp_config_screen.dart';
import 'screens/role_dashboard_screen.dart';
import 'screens/role_management_screen.dart';
import 'screens/user_management_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/sprint_board_screen.dart';
// Removed imports for non-existent screens to resolve analyzer errors
import 'widgets/sidebar_scaffold.dart';
//
import 'widgets/role_guard.dart';
import 'theme/flownet_theme.dart';

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
      builder: (context, child) {
        return AppContainer(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SignoffHubWelcomeScreen(),
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
        final email = state.extra as Map<String, dynamic>?;
        return EmailVerificationScreen(
          email: email?['email'] ?? '',
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
          child: EnhancedDeliverableSetupScreen(),
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
      path: '/client-review/:reportId',
      builder: (context, state) {
        final reportId = state.pathParameters['reportId']!;
        return RouteGuard(
          route: '/client-review',
          child: SidebarScaffold(
            child: ClientReviewScreen(reportId: reportId),
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
      path: '/sprint-console',
            builder: (context, state) => const RouteGuard(
              route: '/sprint-console',
              child: SidebarScaffold(
                child: SprintConsoleScreen(),
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
        route: '/approvals',
        child: SidebarScaffold(
          child: ApprovalsScreen(),
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
      builder: (context, state) => const RouteGuard(
        route: '/repository',
        child: SidebarScaffold(
          child: RepositoryScreen(),
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
    GoRoute(
      path: '/user-management',
      builder: (context, state) => const RouteGuard(
        route: '/user-management',
        child: SidebarScaffold(
          child: UserManagementScreen(),
        ),
      ),
    ),
    
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
    // Removed routes for non-existent screens to resolve analyzer errors
    GoRoute(
      path: '/account',
      redirect: (context, state) => '/profile',
    ),
  ],
);
