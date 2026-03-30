// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../theme/flownet_theme.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _autoSync = true;
  String _language = 'English';
  String _syncFrequency = 'Hourly';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      _darkMode = await SettingsService.getDarkMode();
      _notifications = await SettingsService.getNotifications();
      _autoSync = await SettingsService.getAutoSync();
      _language = await SettingsService.getLanguage();
      _syncFrequency = await SettingsService.getSyncFrequency();
    } catch (e) {
      debugPrint('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: FlownetColors.pureWhite,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Personalize your experience and control how the app behaves.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FlownetColors.coolGray,
                    ),
              ),
              const SizedBox(height: 24),
              _buildSection(
                title: 'Appearance',
                icon: Icons.palette_outlined,
                children: [
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    secondary: const Icon(Icons.dark_mode_outlined),
                    value: _darkMode,
                    onChanged: (value) async {
                      await SettingsService.saveDarkMode(value);
                      setState(() => _darkMode = value);
                    },
                  ),
                  ListTile(
                    title: const Text('Language'),
                    subtitle: Text(_language),
                    trailing: Text(
                      'Edit',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: FlownetColors.coolGray,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    leading: const Icon(Icons.language_outlined),
                    onTap: () => _showLanguageDialog(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Notifications',
                icon: Icons.notifications_none_outlined,
                children: [
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    secondary: const Icon(Icons.notifications_active_outlined),
                    value: _notifications,
                    onChanged: (value) async {
                      await SettingsService.saveNotifications(value);
                      setState(() => _notifications = value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildSection(
                title: 'Data & Sync',
                icon: Icons.sync_outlined,
                children: [
                  SwitchListTile(
                    title: const Text('Auto Sync'),
                    secondary: const Icon(Icons.cloud_sync_outlined),
                    value: _autoSync,
                    onChanged: (value) async {
                      await SettingsService.saveAutoSync(value);
                      setState(() => _autoSync = value);
                    },
                  ),
                  ListTile(
                    title: const Text('Sync Frequency'),
                    subtitle: Text(_syncFrequency),
                    trailing: Text(
                      'Edit',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: FlownetColors.coolGray,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    leading: const Icon(Icons.schedule_outlined),
                    onTap: () => _showSyncFrequencyDialog(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSyncFrequencyDialog() async {
    final frequencies = [
      'Hourly',
      'Every 6 Hours',
      'Daily',
      'Weekly',
      'Manual'
    ];
    String? selected = _syncFrequency;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Select Sync Frequency',
              style: TextStyle(color: FlownetColors.pureWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: frequencies.map((freq) {
              return ListTile(
                title: Text(freq,
                    style: const TextStyle(color: FlownetColors.pureWhite)),
                leading: Icon(
                  selected == freq
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected == freq
                      ? FlownetColors.electricBlue
                      : FlownetColors.coolGray,
                ),
                onTap: () {
                  setState(() => selected = freq);
                  Navigator.pop(context, freq);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (result != null) {
      await SettingsService.saveSyncFrequency(result);
      setState(() => _syncFrequency = result);
    }
  }

  Future<void> _showLanguageDialog() async {
    final languages = ['English', 'Spanish', 'French', 'German', 'Portuguese'];
    String? selected = _language;
    final result = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: FlownetColors.graphiteGray,
          title: const Text('Select Language',
              style: TextStyle(color: FlownetColors.pureWhite)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.map((lang) {
              return ListTile(
                title: Text(lang,
                    style: const TextStyle(color: FlownetColors.pureWhite)),
                leading: Icon(
                  selected == lang
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected == lang
                      ? FlownetColors.electricBlue
                      : FlownetColors.coolGray,
                ),
                onTap: () {
                  setState(() => selected = lang);
                  Navigator.pop(context, lang);
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
    if (result != null) {
      await SettingsService.saveLanguage(result);
      setState(() => _language = result);
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: FlownetColors.coolGray),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: FlownetColors.coolGray,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GlassCard(
          borderRadius: 16,
          padding: const EdgeInsets.symmetric(vertical: 6),
          color: Colors.white.withAlpha(18),
          child: Theme(
            data: Theme.of(context).copyWith(
              listTileTheme: const ListTileThemeData(
                iconColor: FlownetColors.pureWhite,
                textColor: FlownetColors.pureWhite,
              ),
              dividerColor: Colors.white12,
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: children[i],
                  ),
                  if (i != children.length - 1)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(height: 1),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
