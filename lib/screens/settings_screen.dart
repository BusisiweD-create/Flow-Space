// ignore_for_file: use_build_context_synchronously, deprecated_member_use, non_constant_identifier_names, unused_element, use_function_type_syntax_for_parameters, require_trailing_commas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/flownet_theme.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final AuthService _authService = AuthService();
  
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
    _loadUserSettings();
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
  
  
  Widget buildUserInfoSection(Map<String, dynamic>? user) {
    return Card(
      color: FlownetColors.graphiteGray,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: FlownetColors.electricBlue,
              child: Icon(
                Icons.person_outline,
                color: FlownetColors.pureWhite,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?['name'] ?? 'User',
                    style: const TextStyle(
                      color: FlownetColors.pureWhite,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?['email'] ?? 'user@example.com',
                    style: const TextStyle(
                      color: FlownetColors.coolGray,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Role: ${user?['role'] ?? 'Team Member'}',
                    style: const TextStyle(
                      color: FlownetColors.coolGray,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
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
    // Apply theme mode changes
    if (_themeMode == 'dark') {
      // Apply dark theme - this would typically involve updating theme provider
    } else if (_themeMode == 'light') {
      // Apply light theme
    } else {
      // Apply system theme based on device preferences
    }
    
    // Notify theme change
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Theme settings applied successfully'),
        backgroundColor: FlownetColors.electricBlue,
      ),
    );
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
                  buildUserInfoSection(null),
                  const SizedBox(height: 24),

                  // Security Settings
                  buildSectionHeader('Security'),
                  buildSwitchTile(
                    'Biometric Authentication',
                    'Use fingerprint or face recognition to secure your account',
                    _biometricAuth,
                    (value) => setState(() => _biometricAuth = value),
                  ),
                  buildSwitchTile(
                    'Two-Factor Authentication',
                    'Add an extra layer of security to your account',
                    _twoFactorAuth,
                    (value) => setState(() => _twoFactorAuth = value),
                  ),
                  buildDropdownTile(
                    'Auto Logout',
                    'Automatically logout after period of inactivity',
                    _autoLogoutMinutes == 0 ? 'Never' : '$_autoLogoutMinutes minutes',
                    ['15 minutes', '30 minutes', '1 hour', '2 hours', 'Never'],
                    (value) => setState(() => _autoLogoutMinutes = parseLogoutTime(value!)),
                  ),
                  const SizedBox(height: 24),

                  // User Preferences
                  buildSectionHeader('Preferences'),
                  buildSwitchTile(
                    'Dark Mode',
                    'Enable dark theme for better night viewing',
                    _darkMode,
                    (value) => setState(() => _darkMode = value),
                  ),
                  buildSwitchTile(
                    'Notifications',
                    'Receive push notifications for important updates',
                    _notificationsEnabled,
                    (value) => setState(() => _notificationsEnabled = value),
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