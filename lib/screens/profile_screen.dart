import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/glass/glass_card.dart';
import '../widgets/glass/glass_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();

  late final TextEditingController _nameController;
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;

  bool _savingProfile = false;
  bool _changingPassword = false;
  bool _darkThemePreferred = true;

  @override
  void initState() {
    super.initState();
    final user = _authService.currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    setState(() => _savingProfile = true);
    try {
      final success = await _authService.updateProfile({
        'name': _nameController.text.trim(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Profile updated' : 'Failed to update profile'),
            backgroundColor:
                success ? FlownetColors.emeraldGreen : FlownetColors.crimsonRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingProfile = false);
      }
    }
  }

  Future<void> _changePassword() async {
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty) {
      return;
    }
    setState(() => _changingPassword = true);
    try {
      final success = await _authService.changePassword(
        _currentPasswordController.text,
        _newPasswordController.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(success ? 'Password changed' : 'Failed to change password'),
            backgroundColor:
                success ? FlownetColors.emeraldGreen : FlownetColors.crimsonRed,
          ),
        );
      }
      if (success) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
      }
    } finally {
      if (mounted) {
        setState(() => _changingPassword = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile & Settings',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your account, appearance, and notifications.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: FlownetColors.coolGray),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor:
                      FlownetColors.crimsonRed.withValues(alpha: 0.3),
                  child: Text(
                    (user?.name.isNotEmpty ?? false)
                        ? user!.name[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: FlownetColors.pureWhite,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Unknown User',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: FlownetColors.coolGray),
                      ),
                    ],
                  ),
                ),
                GlassButton(
                  onPressed: () {
                    // Avatar upload hook — implement with document service / storage later.
                  },
                  child: const Text('Upload Avatar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _nameController,
                  style: const TextStyle(color: FlownetColors.pureWhite),
                  decoration: const InputDecoration(
                    labelText: 'Full name',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: user?.email ?? ''),
                  style: const TextStyle(color: FlownetColors.coolGray),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassButton(
                    onPressed: _savingProfile ? null : _saveProfile,
                    child: Text(_savingProfile ? 'Saving…' : 'Save Changes'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _darkThemePreferred,
                  onChanged: (value) {
                    setState(() {
                      _darkThemePreferred = value;
                    });
                    // Theme preference hook — can be wired into persisted settings.
                  },
                  activeColor: FlownetColors.crimsonRed,
                  title: const Text(
                    'Dark luxury theme',
                    style: TextStyle(color: FlownetColors.pureWhite),
                  ),
                  subtitle: const Text(
                    'Keep the glassmorphism dark workspace enabled.',
                    style: TextStyle(color: FlownetColors.coolGray),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _currentPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: FlownetColors.pureWhite),
                  decoration: const InputDecoration(
                    labelText: 'Current password',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _newPasswordController,
                  obscureText: true,
                  style: const TextStyle(color: FlownetColors.pureWhite),
                  decoration: const InputDecoration(
                    labelText: 'New password',
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassButton(
                    onPressed: _changingPassword ? null : _changePassword,
                    child: Text(
                      _changingPassword ? 'Updating…' : 'Change Password',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Notification preferences will be wired to backend settings in a later step.',
                  style: TextStyle(color: FlownetColors.coolGray),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Danger Zone',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(color: FlownetColors.crimsonRed),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Delete account is optional and should be wired to a backend endpoint before enabling.',
                  style: TextStyle(color: FlownetColors.coolGray),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: GlassButton(
                    isDestructive: true,
                    onPressed: () {
                      // Placeholder hook for account deletion.
                    },
                    child: const Text('Delete Account'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


