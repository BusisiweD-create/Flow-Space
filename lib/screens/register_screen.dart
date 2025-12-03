import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../models/user_role.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  final _roleController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptTerms = false;
  String _selectedRole = 'Developer';

  final List<Map<String, dynamic>> _roles = [
    {
      'name': 'Developer',
      'description': 'Create and manage deliverables, track progress',
      'icon': Icons.code,
      'color': Colors.blue,
      'permissions': [
        'Create deliverables',
        'Edit own work',
        'View team progress'
      ],
    },
    {
      'name': 'Project Manager',
      'description': 'Lead delivery teams, manage sprints, submit for review',
      'icon': Icons.leaderboard,
      'color': Colors.orange,
      'permissions': [
        'Manage team',
        'Submit for review',
        'View team dashboard'
      ],
    },
    {
      'name': 'Scrum Master',
      'description':
          'Facilitate sprints, remove blockers, ensure team efficiency',
      'icon': Icons.sports_esports,
      'color': Colors.green,
      'permissions': ['Manage sprints', 'View team metrics', 'Remove blockers'],
    },
    {
      'name': 'QA Engineer',
      'description': 'Test deliverables, ensure quality standards',
      'icon': Icons.bug_report,
      'color': Colors.purple,
      'permissions': [
        'Test deliverables',
        'Create test reports',
        'Quality assurance'
      ],
    },
    {
      'name': 'Client',
      'description': 'Review and approve deliverables, provide feedback',
      'icon': Icons.verified_user,
      'color': Colors.teal,
      'permissions': [
        'Review deliverables',
        'Approve submissions',
        'Provide feedback'
      ],
    },
    {
      'name': 'Stakeholder',
      'description': 'Monitor project progress, make strategic decisions',
      'icon': Icons.business,
      'color': Colors.indigo,
      'permissions': [
        'View project status',
        'Strategic oversight',
        'High-level decisions'
      ],
    },
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _roleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: Image.asset(
              'assets/Icons/khono_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          // Content overlay
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 500),
                  child: Card(
                    color: Colors.white.withValues(alpha: 0.15),
                    elevation: 8,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Logo and Title
                            Image.asset(
                              'assets/Icons/khono.png',
                              height: 80,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Create Account',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Join Khonology and streamline your delivery process',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 32),

                            // Name Fields
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _firstNameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'First Name',
                                      labelStyle: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFC10D00), width: 2),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.1),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _lastNameController,
                                    style: const TextStyle(color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'Last Name',
                                      labelStyle: TextStyle(
                                          color: Colors.white
                                              .withValues(alpha: 0.7)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.3)),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.3)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(
                                            color: Color(0xFFC10D00), width: 2),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.1),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Required';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Email Field
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Email',
                                labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFC10D00), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
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

                            // Company Field
                            TextFormField(
                              controller: _companyController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Company',
                                labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFC10D00), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your company';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Role Selection
                            _buildRoleSelection(),
                            const SizedBox(height: 16),

                            // Password Field
                            TextFormField(
                              controller: _passwordController,
                              obscureText: !_isPasswordVisible,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isPasswordVisible = !_isPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFC10D00), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a password';
                                }
                                if (value.length < 8) {
                                  return 'Password must be at least 8 characters';
                                }
                                if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)')
                                    .hasMatch(value)) {
                                  return 'Password must contain uppercase, lowercase, and number';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Confirm Password Field
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_isConfirmPasswordVisible,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Confirm Password',
                                labelStyle: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.7)),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _isConfirmPasswordVisible
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: Colors.white.withValues(alpha: 0.7),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _isConfirmPasswordVisible =
                                          !_isConfirmPasswordVisible;
                                    });
                                  },
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                      color:
                                          Colors.white.withValues(alpha: 0.3)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                      color: Color(0xFFC10D00), width: 2),
                                ),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your password';
                                }
                                if (value != _passwordController.text) {
                                  return 'Passwords do not match';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),

                            // Terms and Conditions
                            Row(
                              children: [
                                Checkbox(
                                  value: _acceptTerms,
                                  fillColor:
                                      WidgetStateProperty.resolveWith((states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return const Color(0xFFC10D00);
                                    }
                                    return Colors.white.withValues(alpha: 0.1);
                                  }),
                                  checkColor: Colors.white,
                                  onChanged: (value) {
                                    setState(() {
                                      _acceptTerms = value ?? false;
                                    });
                                  },
                                ),
                                Expanded(
                                  child: Text(
                                    'I agree to the Terms of Service and Privacy Policy',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          Colors.white.withValues(alpha: 0.9),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Create Account Button
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleRegister,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFC10D00),
                                  foregroundColor: Colors.white,
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
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white),
                                        ),
                                      )
                                    : const Text(
                                        'Create Account',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Sign In Link
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.7)),
                                ),
                                TextButton(
                                  onPressed: () => context.go('/login'),
                                  child: const Text(
                                    'Sign In',
                                    style: TextStyle(
                                      color: Color(0xFFC10D00),
                                      fontWeight: FontWeight.w600,
                                    ),
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
            ), // SafeArea
          ), // Missing closing for SafeArea
        ], // Stack children
      ), // Stack
    ); // Scaffold
  }

  final ErrorHandler _errorHandler = ErrorHandler();
  bool _isLoading = false;

  Widget _buildRoleSelection() {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: _selectedRole,
      decoration: InputDecoration(
        labelText: 'Select Your Role',
        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC10D00), width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.1),
      ),
      dropdownColor: const Color(0xFF8B0000),
      style: const TextStyle(color: Colors.white),
      icon: Icon(
        Icons.arrow_drop_down,
        color: Colors.white.withValues(alpha: 0.7),
      ),
      items: _roles.map((role) {
        return DropdownMenuItem<String>(
          value: role['name'],
          child: Text(
            role['name'],
            style: const TextStyle(color: Colors.white),
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedRole = value;
          });
        }
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a role';
        }
        return null;
      },
    );
  }

  Future<void> _handleRegister() async {
    debugPrint('🔵 Register button clicked!');

    // Check each field individually for debugging
    debugPrint('📝 Form field values:');
    debugPrint('   First Name: "${_firstNameController.text}"');
    debugPrint('   Last Name: "${_lastNameController.text}"');
    debugPrint('   Email: "${_emailController.text}"');
    debugPrint('   Company: "${_companyController.text}"');
    debugPrint(
        '   Password: "${_passwordController.text}" (length: ${_passwordController.text.length})');
    debugPrint('   Confirm Password: "${_confirmPasswordController.text}"');
    debugPrint('   Terms Accepted: $_acceptTerms');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed - check field values above');
      return;
    }
    debugPrint('✅ Form validation passed');

    if (!_acceptTerms) {
      debugPrint('❌ Terms not accepted');
      _errorHandler.showErrorSnackBar(
        context,
        'Please accept the Terms of Service and Privacy Policy',
      );
      return;
    }
    debugPrint('✅ Terms accepted');

    setState(() {
      _isLoading = true;
    });
    debugPrint('🔄 Starting registration process...');

    try {
      // Map role string to UserRole enum
      UserRole userRole;
      switch (_selectedRole.toLowerCase()) {
        case 'project manager':
          userRole = UserRole.deliveryLead;
          break;
        case 'scrum master':
          userRole = UserRole.teamMember;
          break;
        case 'qa engineer':
          userRole = UserRole.teamMember;
          break;
        case 'client':
          userRole = UserRole.clientReviewer;
          break;
        case 'stakeholder':
          userRole = UserRole.systemAdmin;
          break;
        case 'developer':
          userRole = UserRole.teamMember;
          break;
        default:
          userRole = UserRole.teamMember;
      }

      debugPrint('📧 Email: ${_emailController.text.trim()}');
      debugPrint(
          '👤 Name: ${_firstNameController.text.trim()} ${_lastNameController.text.trim()}');
      debugPrint('🎭 Role: $userRole');

      final authService = AuthService();
      final result = await authService.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        userRole,
      );

      debugPrint('📊 Registration result: $result');

      if (result['success'] == true && mounted) {
        _errorHandler.showSuccessSnackBar(context, 'Registration successful!');
        if (mounted) {
          context.go(
            '/email-verification',
            extra: {
              'email': _emailController.text.trim(),
            },
          );
        }
      } else if (mounted) {
        final errorMessage =
            result['error'] ?? 'Registration failed. Please try again.';
        _errorHandler.showErrorSnackBar(
          context,
          errorMessage,
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Registration failed. Please try again.';

        // Provide more specific error messages
        if (e.toString().contains('network') ||
            e.toString().contains('connection')) {
          errorMessage =
              'Network error. Please check your internet connection and try again.';
        } else if (e.toString().contains('timeout')) {
          errorMessage = 'Request timed out. Please try again.';
        } else if (e.toString().contains('server')) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.toString().contains('email')) {
          errorMessage =
              'Email already exists. Please use a different email address.';
        }

        _errorHandler.showErrorSnackBar(context, errorMessage);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
