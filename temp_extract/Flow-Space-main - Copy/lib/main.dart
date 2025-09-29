import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'services/api_service.dart';
import 'screens/welcome_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/email_verification_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/deliverable_setup_screen.dart';
import 'screens/sprint_console_screen.dart';
import 'screens/approvals_screen.dart';
import 'screens/repository_screen.dart';
import 'screens/notifications_screen.dart';
import 'widgets/sidebar_scaffold.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize API Service
  await ApiService.initialize();

  runApp(const ProviderScope(child: KhonoApp()));
}

class KhonoApp extends StatelessWidget {
  const KhonoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Khonology - Deliverable & Sprint Sign-Off Hub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Professional blue
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
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
      builder: (context, state) => const EmailVerificationScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) =>
          SidebarScaffold(child: const DashboardScreen()),
    ),
    GoRoute(
      path: '/deliverable-setup',
      builder: (context, state) =>
          SidebarScaffold(child: const DeliverableSetupScreen()),
    ),
    GoRoute(
      path: '/sprint-console',
      builder: (context, state) =>
          SidebarScaffold(child: const SprintConsoleScreen()),
    ),
    GoRoute(
      path: '/approvals',
      builder: (context, state) =>
          SidebarScaffold(child: const ApprovalsScreen()),
    ),
    GoRoute(
      path: '/repository',
      builder: (context, state) =>
          SidebarScaffold(child: const RepositoryScreen()),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) =>
          SidebarScaffold(child: const NotificationsScreen()),
    ),
    // Optional routes (settings/account) to avoid 404
    GoRoute(
      path: '/settings',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Settings'))),
    ),
    GoRoute(
      path: '/account',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Account'))),
    ),
  ],
);
