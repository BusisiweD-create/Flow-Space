import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../theme/flownet_theme.dart';
import '../widgets/flownet_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authService = AuthService();
      final success = await authService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (success && mounted) {
        ErrorHandler().showSuccessSnackBar(context, 'Login successful!');
        context.go('/dashboard');
      } else if (mounted) {
        ErrorHandler().showErrorSnackBar(context, 'Invalid email or password');
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler().showErrorSnackBar(context, 'Login failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              FlownetColors.charcoalBlack,
              FlownetColors.slate,
              FlownetColors.graphiteGray,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  color: FlownetColors.graphiteGray,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Logo and Title
                          const FlownetLogo(showText: true),
                          const SizedBox(height: 16),
                          Text(
                            'Welcome Back',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: FlownetColors.pureWhite,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Sign in to your Flownet account',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: FlownetColors.coolGray,
                                ),
                          ),
                          const SizedBox(height: 32),

                          // Email Field
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: FlownetColors.pureWhite),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: FlownetColors.coolGray),
                              prefixIcon: const Icon(Icons.email_outlined, color: FlownetColors.electricBlue),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: FlownetColors.slate),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: FlownetColors.slate),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: FlownetColors.electricBlue),
                              ),
                              filled: true,
                              fillColor: FlownetColors.slate,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your email';
                              }
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                  .hasMatch(value)) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field
                          TextFormField(
                            controller: _passwordController,
                            obscureText: !_isPasswordVisible,
                            style: const TextStyle(color: FlownetColors.pureWhite),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: FlownetColors.coolGray),
                              prefixIcon: const Icon(Icons.lock_outlined, color: FlownetColors.electricBlue),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: FlownetColors.coolGray,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: FlownetColors.slate),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: FlownetColors.slate),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: FlownetColors.electricBlue),
                              ),
                              filled: true,
                              fillColor: FlownetColors.slate,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              if (value.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                _showForgotPasswordDialog();
                              },
                              child: const Text(
                                'Forgot Password?',
                                style: TextStyle(color: FlownetColors.electricBlue),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Sign In Button
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FlownetColors.electricBlue,
                                foregroundColor: FlownetColors.pureWhite,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          FlownetColors.pureWhite,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Demo Users Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: FlownetColors.slate,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: FlownetColors.electricBlue.withValues(alpha: 0.3)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Demo Users:',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: FlownetColors.electricBlue,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                _buildDemoUser('team@example.com', 'Team Member'),
                                _buildDemoUser('lead@example.com', 'Delivery Lead'),
                                _buildDemoUser('client@example.com', 'Client Reviewer'),
                                _buildDemoUser('admin@example.com', 'System Admin'),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Register Link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "Don't have an account? ",
                                style: TextStyle(color: FlownetColors.coolGray),
                              ),
                              TextButton(
                                onPressed: () {
                                  context.go('/register');
                                },
                                child: const Text(
                                  'Sign Up',
                                  style: TextStyle(color: FlownetColors.electricBlue),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoUser(String email, String role) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            '$email - ',
            style: const TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 12,
            ),
          ),
          Text(
            role,
            style: const TextStyle(
              color: FlownetColors.electricBlue,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: FlownetColors.charcoalBlack,
        title: const Text(
          'Reset Password',
          style: TextStyle(color: FlownetColors.pureWhite),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enter your email address and we\'ll send you a link to reset your password.',
              style: TextStyle(color: FlownetColors.coolGray),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: emailController,
              style: const TextStyle(color: FlownetColors.pureWhite),
              decoration: const InputDecoration(
                labelText: 'Email',
                labelStyle: TextStyle(color: FlownetColors.coolGray),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.slate),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: FlownetColors.electricBlue),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: FlownetColors.coolGray),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (emailController.text.isNotEmpty) {
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                
                try {
                  final authService = AuthService();
                  await authService.forgotPassword(emailController.text);
                  
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('Password reset email sent!'),
                        backgroundColor: FlownetColors.electricBlue,
                      ),
                    );
                    navigator.pop();
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: FlownetColors.crimsonRed,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: FlownetColors.electricBlue,
            ),
            child: const Text(
              'Send Reset Link',
              style: TextStyle(color: FlownetColors.pureWhite),
            ),
          ),
        ],
      ),
    );
  }
}
