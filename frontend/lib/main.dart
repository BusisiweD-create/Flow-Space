import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/deliverable_setup_screen.dart';
import 'screens/sprint_console_screen.dart';
import 'screens/signoff_report_builder_screen.dart';
import 'screens/client_review_screen.dart';
import 'screens/audit_trail_screen.dart';
import 'screens/repository_screen.dart';
import 'screens/profile_screen.dart';
import 'components/main_layout.dart';
import 'screens/client_reviewer_dashboard.dart';
import 'screens/qa_engineer_dashboard.dart';
import 'screens/delivery_manager_dashboard.dart';
import 'models/user_role.dart';
import 'providers/api_auth_riverpod_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    // Initialize API Service
    await ApiService.initialize();
    
    runApp(const ProviderScope(child: KhonoApp()));
  // ignore: empty_catches
  } catch (e) {
}
}

class KhonoApp extends ConsumerWidget {
  const KhonoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Use read instead of watch to prevent immediate initialization
    // Theme provider will be initialized when needed by individual screens
    final themeMode = ref.read(themeProvider);

    final router = GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const LoginScreen(),
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
          builder: (context, state) => const EmailVerificationScreen(),
        ),
        GoRoute(
          path: '/dashboard',
          builder: (context, state) => wrapWithLayout(const DashboardScreen(), '/dashboard'),
          redirect: (context, state) {
            final user = ref.read(apiCurrentUserProvider);
            if (user == null) {
              return '/login';
            }
            switch (user.role) {
              case UserRole.clientReviewer:
                return '/client-reviewer-dashboard';
              case UserRole.deliveryLead:
                return '/delivery-manager-dashboard';
              default:
                return '/dashboard';
            }
          },
        ),
        GoRoute(
          path: '/client-reviewer-dashboard',
          builder: (context, state) => wrapWithLayout(const ClientReviewerDashboard(), '/client-reviewer-dashboard'),
        ),
        GoRoute(
          path: '/qa-engineer-dashboard',
          builder: (context, state) => wrapWithLayout(const QaEngineerDashboard(), '/qa-engineer-dashboard'),
        ),
        GoRoute(
          path: '/delivery-manager-dashboard',
          builder: (context, state) => wrapWithLayout(const DeliveryManagerDashboard(), '/delivery-manager-dashboard'),
        ),
        GoRoute(
          path: '/deliverable-setup',
          builder: (context, state) => wrapWithLayout(const DeliverableSetupScreen(), '/deliverable-setup'),
        ),
        GoRoute(
          path: '/sprint-console',
          builder: (context, state) => wrapWithLayout(const SprintConsoleScreen(), '/sprint-console'),
        ),
        GoRoute(
          path: '/signoff-builder',
          builder: (context, state) => wrapWithLayout(const SignoffReportBuilderScreen(), '/signoff-builder'),
        ),
        GoRoute(
          path: '/client-review',
          builder: (context, state) => wrapWithLayout(const ClientReviewScreen(), '/client-review'),
        ),
        GoRoute(
          path: '/audit-trail',
          builder: (context, state) => wrapWithLayout(const AuditTrailScreen(), '/audit-trail'),
        ),
        GoRoute(
          path: '/repository',
          builder: (context, state) => wrapWithLayout(const RepositoryScreen(), '/repository'),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => wrapWithLayout(const ProfileScreen(), '/profile'),
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Khonology - Deliverable & Sprint Sign-Off Hub',
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

