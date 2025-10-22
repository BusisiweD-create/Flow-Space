// ignore_for_file: use_build_context_synchronously, deprecated_member_use, non_constant_identifier_names, unused_element, use_function_type_syntax_for_parameters, require_trailing_commas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/flownet_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../providers/service_providers.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  User? _currentUser;

  // Helper methods for role-based settings filtering
  bool get _canAccessSecuritySettings => _currentUser?.isSystemAdmin == true || _currentUser?.isDeliveryLead == true || _currentUser?.isClientReviewer == true;
  
  bool get _canAccessAccountManagement => _currentUser?.isSystemAdmin == true || _currentUser?.isDeliveryLead == true;
  
  bool get _canAccessAdvancedSettings => _currentUser?.isSystemAdmin == true;
  
  bool get _canAccessTeamManagement => _currentUser?.isSystemAdmin == true || _currentUser?.isDeliveryLead == true;
  
  bool get _canAccessSystemSettings => _currentUser?.isSystemAdmin == true;
  
  // User preferences state
  bool _darkMode = true;
  bool _notificationsEnabled = true;
  bool _syncOnMobileData = false;
  bool _autoBackup = false;
  bool _shareAnalytics = true;
  String _language = 'English';
  bool _biometricAuth = false;
  bool _twoFactorAuth = false;
  String _themeMode = 'system';
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _soundEffects = true;
  bool _hapticFeedback = true;
  int _autoLogoutMinutes = 30;
  
  // App settings state
  // Account management
  String _currentPassword = '';
  String _newPassword = '';
  String _confirmPassword = '';
  
  // UI state
  bool _showAdvancedSettings = false;
  bool _showSecuritySection = false;
  bool _showAccountSection = false;
  

  
  VoidCallback get _clearCache => _clearAppCache;

  Future<void> _clearAppCache() async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Clearing cache...'),
          backgroundColor: FlownetColors.amberOrange,
        ),
      );

      // Simulate cache clearing process
      await Future.delayed(const Duration(seconds: 1));

      // Clear actual cache (this would be implemented with actual cache clearing logic)
      await SharedPreferences.getInstance();
      // Add any cache clearing logic here

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cache cleared successfully'),
          backgroundColor: FlownetColors.emeraldGreen,
        ),
      );

      // Refresh cache size display
      _calculateCacheSize();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to clear cache: \$e'),
          backgroundColor: FlownetColors.crimsonRed,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadUserSettings();
  }
  
  Future<void> _loadCurrentUser() async {
    try {
      // Initialize auth service if needed
      await _authService.initialize();
      setState(() {
        _currentUser = _authService.currentUser;
      });
    } catch (e) {
      debugPrint('Error loading current user: $e');
    }
  }
  
  Future<void> _loadUserSettings() async {
    try {
      // Load user settings from backend or local storage
      final settings = await ApiService.getUserSettings();
      final prefs = await SharedPreferences.getInstance();
      
      if (settings != null) {
        setState(() {
          _darkMode = settings['dark_mode'] ?? true;
          _notificationsEnabled = settings['notifications_enabled'] ?? true;
          _syncOnMobileData = settings['sync_on_mobile_data'] ?? false;
          _autoBackup = settings['auto_backup'] ?? false;
          _shareAnalytics = settings['share_analytics'] ?? true;
          _language = settings['language'] ?? 'English';
          _biometricAuth = settings['biometric_auth'] ?? false;
          _twoFactorAuth = settings['two_factor_auth'] ?? false;
          _themeMode = settings['theme_mode'] ?? 'system';
          _emailNotifications = settings['email_notifications'] ?? true;
          _pushNotifications = settings['push_notifications'] ?? true;
          _soundEffects = settings['sound_effects'] ?? true;
          _hapticFeedback = settings['haptic_feedback'] ?? true;
          _autoLogoutMinutes = settings['auto_logout_minutes'] ?? 30;
          
          // Load local preferences
          _showAdvancedSettings = prefs.getBool('show_advanced_settings') ?? false;
          _showSecuritySection = prefs.getBool('show_security_section') ?? false;
          _showAccountSection = prefs.getBool('show_account_section') ?? false;
        } as Function());
      }
      
      // Calculate cache size
      _calculateCacheSize();
      
    } catch (e) {
      // Fallback to default settings
      debugPrint('Error loading settings: $e');
    } finally {
    }
  }
  
  Future<void> _saveSettings() async {
    try {
      final settings = {
        'dark_mode': _darkMode,
        'notifications_enabled': _notificationsEnabled,
        'sync_on_mobile_data': _syncOnMobileData,
        'auto_backup': _autoBackup,
        'share_analytics': _shareAnalytics,
        'language': _language,
        'biometric_auth': _biometricAuth,
        'two_factor_auth': _twoFactorAuth,
        'theme_mode': _themeMode,
        'email_notifications': _emailNotifications,
        'push_notifications': _pushNotifications,
        'sound_effects': _soundEffects,
        'haptic_feedback': _hapticFeedback,
        'auto_logout_minutes': _autoLogoutMinutes,
      };
      
      // Save to backend
      await ApiService.updateUserSettings(settings);
      
      // Save local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('show_advanced_settings', _showAdvancedSettings);
      await prefs.setBool('show_security_section', _showSecuritySection);
      await prefs.setBool('show_account_section', _showAccountSection);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings saved successfully'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      
      // Apply theme changes immediately
      _applyThemeSettings();
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: $e'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    } finally {
    }
  }
  
  Future<void> _resetToDefaults() async {
    setState(() {
      _darkMode = true;
      _notificationsEnabled = true;
      _syncOnMobileData = false;
      _autoBackup = false;
      _shareAnalytics = true;
      _language = 'English';
      _biometricAuth = false;
      _twoFactorAuth = false;
      _themeMode = 'system';
      _emailNotifications = true;
      _pushNotifications = true;
      _soundEffects = true;
      _hapticFeedback = true;
      _autoLogoutMinutes = 30;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Settings reset to defaults'),
        backgroundColor: FlownetColors.amberOrange,
      ),
    );
  }
  
  Future<void> _calculateCacheSize() async {
    // Simulate cache size calculation
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {});
  }
  
  void applyThemeSettings() {
    // Apply theme mode changes
    if (_themeMode == 'dark') {
      // Apply dark theme
    } else if (_themeMode == 'light') {
      // Apply light theme
    } else {
      // Apply system theme
    }
    
    // Notify theme change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme settings applied'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
  }
  
  Future<void> changePassword() async {
    if (_newPassword != _confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: FlownetColors.crimsonRed,
        ),
      );
      return;
    }
    
    if (_newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password must be at least 6 characters'),
          backgroundColor: FlownetColors.crimsonRed,
        ),
      );
      return;
    }
    
    try {
      final success = await _authService.changePassword(_currentPassword, _newPassword);
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
        
        // Clear password fields
        setState(() {
          _currentPassword = '';
          _newPassword = '';
          _confirmPassword = '';
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to change password'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
            backgroundColor: FlownetColors.crimsonRed,
          ),
        );
      }
    } finally {
    }
  }
  
  void toggleAdvancedSettings() {
    setState(() {
      _showAdvancedSettings = !_showAdvancedSettings;
    });
  }
  
  
  
  void clearCache() {
    // Clear app cache logic would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
  }
  
  void exportData() {
    // Data export logic would go here
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data export started'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
  }
  
  
  Widget buildUserInfoSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _currentUser?.role.color ?? Colors.grey,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _currentUser?.role.icon ?? Icons.person,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _currentUser?.name ?? 'Guest User',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _currentUser?.email ?? 'No email',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (_currentUser?.role.color ?? Colors.grey).withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _currentUser?.role.displayName ?? 'No Role',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _currentUser?.role.color ?? Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: FlownetColors.coolGray,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
  
  Widget buildSwitchTile(String title, String subtitle, bool value, Function(bool) onChanged) {
    return Card(
      color: FlownetColors.graphiteGray,
      margin: const EdgeInsets.only(bottom: 8),
      child: SwitchListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: FlownetColors.pureWhite,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: FlownetColors.coolGray,
            fontSize: 12,
          ),
        ),
        value: value,
        onChanged: onChanged,
        thumbColor: MaterialStateProperty.all(FlownetColors.electricBlue),
        trackColor: MaterialStateProperty.resolveWith((states) {
          return states.contains(MaterialState.selected) 
            ? FlownetColors.electricBlue.withOpacity(0.5)
            : FlownetColors.slate;
        }),
      ),
    );
  }
  
  Widget buildDropdownTile(String title, String subtitle, String value, List<String> items, Function(String?) onChanged) {
    return Card(
      color: FlownetColors.graphiteGray,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(
            color: FlownetColors.pureWhite,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: FlownetColors.coolGray,
            fontSize: 12,
          ),
        ),
        trailing: DropdownButton<String>(
          value: value,
          onChanged: onChanged,
          dropdownColor: FlownetColors.graphiteGray,
          icon: const Icon(Icons.arrow_drop_down, color: FlownetColors.coolGray),
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(
                value,
                style: const TextStyle(color: FlownetColors.pureWhite),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
  
  Widget buildActionTile(String title, IconData icon, VoidCallback onTap) {
    return Card(
      color: FlownetColors.graphiteGray,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: FlownetColors.coolGray),
        title: Text(
          title,
          style: const TextStyle(
            color: FlownetColors.pureWhite,
            fontSize: 14,
          ),
        ),
        onTap: onTap,
        trailing: const Icon(Icons.chevron_right, color: FlownetColors.coolGray),
      ),
    );
  }
  
  
  Widget buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: const TextStyle(
              color: FlownetColors.coolGray,
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: FlownetColors.pureWhite,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  int parseLogoutTime(String value) {
    switch (value) {
      case '15 minutes':
        return 15;
      case '30 minutes':
        return 30;
      case '1 hour':
        return 60;
      case '2 hours':
        return 120;
      case 'Never':
        return 0;
      default:
        return 30;
    }
  }
  
  void _applyThemeSettings() {
    // Apply theme mode changes immediately using theme provider
    ref.read(themeProvider.notifier).toggleTheme(_darkMode);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_darkMode ? 'Dark mode enabled' : 'Light mode enabled'),
          backgroundColor: FlownetColors.electricBlue,
        ),
      );
    }
  }

  void _applyNotificationSettings() {
    // Apply notification settings immediately
    if (_notificationsEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications enabled'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      // In a real implementation, this would register for push notifications
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notifications disabled'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      // In a real implementation, this would unregister from push notifications
    }
  }

  void _applyBiometricSettings() {
    // Apply biometric authentication settings
    if (_biometricAuth) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication enabled'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      // In a real implementation, this would set up biometric authentication
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Biometric authentication disabled'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      // In a real implementation, this would disable biometric authentication
    }
  }

  void _applyTwoFactorSettings() {
    // Apply two-factor authentication settings
    if (_twoFactorAuth) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication enabled'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      // In a real implementation, this would set up two-factor authentication
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Two-factor authentication disabled'),
            backgroundColor: FlownetColors.electricBlue,
          ),
        );
      }
      // In a real implementation, this would disable two-factor authentication
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FlownetColors.charcoalBlack,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Settings'),
            backgroundColor: FlownetColors.charcoalBlack,
            pinned: true,
            floating: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.save),
                onPressed: _saveSettings,
                tooltip: 'Save Settings',
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // User Info Section
                  buildUserInfoSection(),
                  const SizedBox(height: 24),

                  // Security Settings - Only for System Admins, Delivery Leads, and Client Reviewers
                  if (_canAccessSecuritySettings) ...[
                    buildSectionHeader('Security'),
                    buildSwitchTile(
                      'Biometric Authentication',
                      'Use fingerprint or face recognition to secure your account',
                      _biometricAuth,
                      (value) {
                        setState(() => _biometricAuth = value);
                        _applyBiometricSettings();
                      },
                    ),
                    buildSwitchTile(
                      'Two-Factor Authentication',
                      'Add an extra layer of security to your account',
                      _twoFactorAuth,
                      (value) {
                        setState(() => _twoFactorAuth = value);
                        _applyTwoFactorSettings();
                      },
                    ),
                    buildDropdownTile(
                      'Auto Logout',
                      'Automatically logout after period of inactivity',
                      _autoLogoutMinutes == 0 ? 'Never' : '$_autoLogoutMinutes minutes',
                      ['15 minutes', '30 minutes', '1 hour', '2 hours', 'Never'],
                      (value) => setState(() => _autoLogoutMinutes = parseLogoutTime(value!)),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // User Preferences
                  buildSectionHeader('Preferences'),
                  buildSwitchTile(
                    'Dark Mode',
                    'Enable dark theme for better night viewing',
                    _darkMode,
                    (value) {
                      setState(() => _darkMode = value);
                      _applyThemeSettings();
                    },
                  ),
                  buildSwitchTile(
                    'Notifications',
                    'Receive push notifications for important updates',
                    _notificationsEnabled,
                    (value) {
                      setState(() => _notificationsEnabled = value);
                      _applyNotificationSettings();
                    },
                  ),
                  buildSwitchTile(
                    'Sync on Mobile Data',
                    'Allow data synchronization when using mobile data',
                    _syncOnMobileData,
                    (value) => setState(() => _syncOnMobileData = value),
                  ),
                  buildSwitchTile(
                    'Auto Backup',
                    'Automatically backup your data daily',
                    _autoBackup,
                    (value) => setState(() => _autoBackup = value),
                  ),
                  buildSwitchTile(
                    'Share Analytics',
                    'Help improve the app by sharing anonymous usage data',
                    _shareAnalytics,
                    (value) => setState(() => _shareAnalytics = value),
                  ),
                  buildDropdownTile(
                    'Language',
                    'Choose your preferred language',
                    _language,
                    ['English', 'Spanish', 'French', 'German', 'Chinese'],
                    (value) => setState(() => _language = value!),
                  ),
                  const SizedBox(height: 24),

                  // App Settings
                  buildSectionHeader('App Settings'),
                  buildSwitchTile(
                    'Developer Mode',
                    'Enable advanced developer features',
                    _showAdvancedSettings,
                    (value) => setState(() => _showAdvancedSettings = value),
                  ),
                  buildSwitchTile(
                    'Performance Mode',
                    'Optimize for better performance (may use more battery)',
                    false,
                    (value) {},
                  ),
                  buildSwitchTile(
                    'Debug Logging',
                    'Enable detailed logging for troubleshooting',
                    false,
                    (value) {},
                  ),
                  const SizedBox(height: 24),

                  // Team Management Settings - Only for System Admins and Delivery Leads
                  if (_canAccessTeamManagement) ...[ 
                    buildSectionHeader('Team Management'),
                    buildSwitchTile(
                      'Team Notifications',
                      'Receive notifications about team activities',
                      true,
                      (value) {},
                    ),
                    buildSwitchTile(
                      'Auto-assign Tasks',
                      'Automatically assign new tasks to available team members',
                      true,
                      (value) {},
                    ),
                    buildDropdownTile(
                      'Default Task Priority',
                      'Set default priority for new tasks',
                      'Medium',
                      ['Low', 'Medium', 'High', 'Critical'],
                      (value) {},
                    ),
                    const SizedBox(height: 24),
                  ],

                  // System Settings - Only for System Admins
                  if (_canAccessSystemSettings) ...[
                    buildSectionHeader('System Administration'),
                    buildSwitchTile(
                      'Maintenance Mode',
                      'Put the system in maintenance mode',
                      false,
                      (value) {},
                    ),
                    buildSwitchTile(
                      'Force Password Reset',
                      'Require all users to reset their passwords',
                      false,
                      (value) {},
                    ),
                    buildActionTile(
                      'View Audit Logs',
                      Icons.history,
                      () {},
                    ),
                    buildActionTile(
                      'System Diagnostics',
                      Icons.bug_report,
                      () {},
                    ),
                    buildActionTile(
                      'Database Backup',
                      Icons.backup,
                      () {},
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Actions
                  buildSectionHeader('Actions'),
                  buildActionTile(
                    'Clear Cache',
                    Icons.delete_outline,
                    _clearCache,
                  ),
                  buildActionTile(
                    'Export Data',
                    Icons.file_download_outlined,
                    exportData,
                  ),
                  buildActionTile(
                    'Reset to Defaults',
                    Icons.restore,
                    _resetToDefaults,
                  ),
                  const SizedBox(height: 24),

                  // App Info
                  buildSectionHeader('App Information'),
                  buildInfoRow('Version', '1.0.0'),
                  buildInfoRow('Build Number', '2024.01.001'),
                  buildInfoRow('Last Updated', 'January 2024'),

                  // Save Button
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FlownetColors.electricBlue,
                      foregroundColor: FlownetColors.pureWhite,
                      minimumSize: const Size(double.infinity, 48),
                    ),
                    child: const Text('Save Settings'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}