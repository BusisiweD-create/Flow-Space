// ignore_for_file: unused_element, no_leading_underscores_for_local_identifiers, duplicate_ignore, prefer_const_constructors, deprecated_member_use, unused_field

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../utils/git_utils.dart';
import '../widgets/deliverable_card.dart';
import '../widgets/metrics_card.dart';
import '../widgets/sprint_performance_chart.dart';
import '../components/performance_visualizations.dart';
import '../services/backend_settings_service.dart';
import '../services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';
import '../providers/dashboard_provider.dart';
import '../models/deliverable.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String? _branchName;
  
  @override
  void initState() {
    super.initState();
    // Load dashboard data when the screen is first displayed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboardData();
    });
    
    // Load Git branch name
    _loadBranchName();
  }
  
  Future<void> _loadBranchName() async {
    final branchName = await GitUtils.getCurrentBranchName();
    if (mounted) {
      setState(() {
        _branchName = branchName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer(
        builder: (context, ref, child) {
          final dashboardState = ref.watch(dashboardProvider);
          
          if (dashboardState.isLoading && dashboardState.deliverables.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (dashboardState.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading dashboard data',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dashboardState.error!,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      ref.read(dashboardProvider.notifier).loadDashboardData();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                TabBar(
                  tabs: const [
                    Tab(text: 'Overview'),
                    Tab(text: 'Performance'),
                  ],
                  labelColor: Theme.of(context).colorScheme.primary,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Theme.of(context).colorScheme.primary,
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      // Overview Tab
                      RefreshIndicator(
                        onRefresh: () async {
                          await ref.read(dashboardProvider.notifier).refreshData();
                        },
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome Section
                              _buildWelcomeSection(),
                              const SizedBox(height: 24),

                              // Key Metrics Row
                              _buildMetricsRow(),
                              const SizedBox(height: 24),

                              // Reminders Section
                              _buildRemindersSection(),
                              const SizedBox(height: 24),

                              // Sprint Performance Chart
                              _buildSprintPerformanceSection(),
                              const SizedBox(height: 24),

                              // Deliverables Section
                              _buildDeliverablesSection(),
                            ],
                          ),
                        ),
                      ),
                      
                      // Performance Tab
                      PerformanceVisualizations(dashboardData: dashboardState.analyticsData),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateDeliverableDialog();
        },
        icon: const Icon(Icons.add),
        label: const Text('New Deliverable'),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: const Icon(
                Icons.dashboard,
                size: 30,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to Khonology',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Deliverable & Sprint Sign-Off Hub',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Track deliverables, monitor sprint performance, and manage client approvals',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow() {
    final dashboardState = ref.watch(dashboardProvider);
    final deliverables = dashboardState.deliverables;
    
    final totalDeliverables = deliverables.length;
    final approvedDeliverables = deliverables.where((d) => d.status == DeliverableStatus.approved).length;
    final pendingDeliverables = deliverables.where((d) => d.status == DeliverableStatus.submitted).length;

    return Row(
      children: [
        Expanded(
          child: MetricsCard(
            title: 'Total Deliverables',
            value: totalDeliverables.toString(),
            icon: Icons.assignment,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricsCard(
            title: 'Approved',
            value: approvedDeliverables.toString(),
            icon: Icons.check_circle,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricsCard(
            title: 'Pending Review',
            value: pendingDeliverables.toString(),
            icon: Icons.pending,
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: MetricsCard(
            title: 'Sprints',
            value: dashboardState.sprints.length.toString(),
            icon: Icons.timeline,
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildSprintPerformanceSection() {
    final dashboardState = ref.watch(dashboardProvider);
    final sprints = dashboardState.sprints;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Sprint Performance',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                TextButton.icon(
                  onPressed: () {
                    _showSprintManagementDialog();
                  },
                  icon: const Icon(Icons.timeline),
                  label: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: sprints.isEmpty
                  ? Center(
                      child: Text(
                        'No sprint data available',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    )
                  : SprintPerformanceChart(sprints: sprints.map((sprint) => {
                      'id': sprint.id,
                      'name': sprint.name,
                      'start_date': sprint.startDate,
                      'end_date': sprint.endDate,
                      'planned_points': sprint.committedPoints,
                      'completed_points': sprint.completedPoints,
                      'status': sprint.endDate.isBefore(DateTime.now()) ? 'completed' : 'active',
                    },).toList(),),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    final dashboardState = ref.watch(dashboardProvider);
    final deliverables = dashboardState.deliverables;
    
    // Get pending approvals (deliverables that are submitted but not approved)
    final pendingApprovals = deliverables.where((d) => 
        d.status == DeliverableStatus.submitted,).toList();
    
    if (pendingApprovals.isEmpty) {
      return const SizedBox.shrink(); // Hide section if no reminders
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reminders & Escalations',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
                const Icon(
                  Icons.notifications_active,
                  color: Colors.orange,
                  size: 24,
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            Text(
              'Pending Approval:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
            ),
            const SizedBox(height: 8),
            ...pendingApprovals.map((deliverable) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.pending, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      deliverable.title,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),),
            
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () {
                // Simulate sending reminders
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Reminders sent for ${pendingApprovals.length} pending approvals'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.notifications, size: 16),
              label: const Text('Send Reminder to All'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverablesSection() {
    final dashboardState = ref.watch(dashboardProvider);
    final deliverables = dashboardState.deliverables;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Deliverables',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            TextButton.icon(
              onPressed: () {
                _showAllDeliverablesDialog();
              },
              icon: const Icon(Icons.list),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (deliverables.isEmpty)
          Center(
            child: Text(
              'No deliverables found',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          )
        else
          ...deliverables.take(5).map((deliverable) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeliverableCard(
                  deliverable: deliverable,
                  onTap: () {
                    _showDeliverableDetailsDialog(deliverable);
                  },
                ),
              ),),
      ],
    );
  }

  void _showCreateDeliverableDialog() {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();
    final TextEditingController dueDateController = TextEditingController();
    String selectedPriority = 'Medium';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Create New Deliverable'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Deliverable Name',
                    hintText: 'Enter deliverable name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Enter description',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: dueDateController,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    hintText: 'YYYY-MM-DD',
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                  ),
                  initialValue: selectedPriority,
                  items: ['Low', 'Medium', 'High'].map((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedPriority = newValue;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('New deliverable created')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications at this time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSettingsDialog() {
    bool darkMode = false;
    // ignore: no_leading_underscores_for_local_identifiers
    bool _notifications = true;
    String selectedLanguage = 'English';

    // Load saved settings
    // ignore: no_leading_underscores_for_local_identifiers
    Future<void> _loadSettings() async {
      try {
        final settings = await BackendSettingsService.getUserSettings();
        setState(() {
          darkMode = settings['dark_mode'] ?? false;
          _notifications = settings['notifications_enabled'] ?? true;
          selectedLanguage = settings['language'] ?? 'English';
        });
      } catch (e) {
        // Fallback to theme provider state if backend fails
        final currentTheme = ref.read(themeProvider);
        setState(() {
          darkMode = currentTheme == ThemeMode.dark;
          _notifications = true;
          selectedLanguage = 'English';
        });
      }
    }

    // Save settings
    Future<void> saveSettings() async {
      try {
        // Save to backend using batch update
        await BackendSettingsService.updateMultipleSettings({
          'dark_mode': darkMode,
          'notifications_enabled': _notifications,
          'language': selectedLanguage,
        });
        
        // Also update theme using ThemeProvider
        await ref.read(themeProvider.notifier).setTheme(darkMode);
        
        // Update notification service with new settings
        await NotificationService.setNotificationsEnabled(_notifications);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        // Only update theme if backend fails (settings won't persist)
        await ref.read(themeProvider.notifier).setTheme(darkMode);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings could not be saved to backend')),
        );
        Navigator.of(context).pop();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Load settings when dialog opens and sync with theme provider
          Future.microtask(() async {
            await _loadSettings();
            // Ensure UI matches theme provider state - use the actual theme provider state
            final currentTheme = ref.read(themeProvider);
            setState(() {
              darkMode = currentTheme == ThemeMode.dark;
            });
          });
          return AlertDialog(
            title: const Text('Settings'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Theme Settings
                  const Text('Appearance', style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Dark Mode'),
                    value: darkMode,
                    onChanged: (value) {
                      setState(() => darkMode = value);
                    },
                  ),
                  const Divider(),

                  // Notification Settings
                  const Text('Notifications', style: TextStyle(fontWeight: FontWeight.bold)),
                  SwitchListTile(
                    title: const Text('Enable Notifications'),
                    value: _notifications,
                    onChanged: (value) {
                      setState(() => _notifications = value);
                    },
                  ),
                  const Divider(),

                  // Language Settings
                  const Text('Language', style: TextStyle(fontWeight: FontWeight.bold)),
                  DropdownButton<String>(
                    value: selectedLanguage,
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() => selectedLanguage = newValue);
                      }
                    },
                    items: <String>['English', 'Spanish', 'French', 'German']
                      .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                  ),
                  const Divider(),

                  // Advanced Settings
                  const Text('Advanced', style: TextStyle(fontWeight: FontWeight.bold)),
                  ListTile(
                    title: const Text('Data Synchronization'),
                    subtitle: const Text('Manage how your data syncs'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showDataSyncSettingsDialog();
                    },
                  ),
                  ListTile(
                    title: const Text('Privacy Settings'),
                    subtitle: const Text('Manage your privacy preferences'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.of(context).pop();
                      _showPrivacySettingsDialog();
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => saveSettings(),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showDataSyncSettingsDialog() {
    bool syncOnMobileData = false;
    bool autoBackup = false;

    // Load saved settings
    loadDataSyncSettings() async {
      try {
        final settings = await BackendSettingsService.getUserSettings();
        setState(() {
          syncOnMobileData = settings['sync_on_mobile_data'] ?? false;
          autoBackup = settings['auto_backup'] ?? false;
        });
      } catch (e) {
        // Fallback to default settings if backend fails
        setState(() {
          syncOnMobileData = false;
          autoBackup = false;
        });
      }
    }

    // Save settings
    _saveDataSyncSettings() async {
      try {
        // Save to backend using batch update
        await BackendSettingsService.updateMultipleSettings({
          'sync_on_mobile_data': syncOnMobileData,
          'auto_backup': autoBackup,
        });
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data sync settings saved successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        // If backend fails, just show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data sync settings could not be saved to backend')),
        );
        Navigator.of(context).pop();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Load settings when dialog opens
          Future.microtask(() async {
            try {
              final settings = await BackendSettingsService.getUserSettings();
              setState(() {
                syncOnMobileData = settings['sync_on_mobile_data'] ?? false;
                autoBackup = settings['auto_backup'] ?? false;
              });
            } catch (e) {
              setState(() {
                syncOnMobileData = false;
                autoBackup = false;
              });
            }
          });

          return AlertDialog(
            title: const Text('Data Synchronization Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Sync over Mobile Data'),
                  value: syncOnMobileData,
                  onChanged: (value) {
                    setState(() {
                      syncOnMobileData = value;
                    });
                  },
                ),
                SwitchListTile(
                  title: const Text('Automatic Backup'),
                  value: autoBackup,
                  onChanged: (value) {
                    setState(() => autoBackup = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _saveDataSyncSettings,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showPrivacySettingsDialog() {
    bool _shareAnalytics = false;
    bool _allowNotifications = true;

    // Load saved settings
    _loadPrivacySettings() async {
      try {
        final settings = await BackendSettingsService.getUserSettings();
        setState(() {
          _shareAnalytics = settings['share_analytics'] ?? false;
          _allowNotifications = settings['allow_notifications'] ?? true;
        });
      } catch (e) {
        // Fallback to default settings if backend fails
        setState(() {
          _shareAnalytics = false;
          _allowNotifications = true;
        });
      }
    }

    // Save settings
    _savePrivacySettings() async {
      try {
        // Save to backend
        await BackendSettingsService.setShareAnalytics(_shareAnalytics);
        await BackendSettingsService.setAllowNotifications(_allowNotifications);
        
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings saved successfully')),
        );
        Navigator.of(context).pop();
      } catch (e) {
        // If backend fails, just show error message
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Privacy settings could not be saved to backend')),
        );
        Navigator.of(context).pop();
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Load settings when dialog opens
          Future.microtask(() => _loadPrivacySettings());

          return AlertDialog(
            title: const Text('Privacy Settings'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: const Text('Share Analytics Data'),
                  value: _shareAnalytics,
                  onChanged: (value) {
                    setState(() => _shareAnalytics = value);
                  },
                ),
                SwitchListTile(
                  title: const Text('Allow Notifications'),
                  value: _allowNotifications,
                  onChanged: (value) {
                    setState(() => _allowNotifications = value);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _savePrivacySettings,
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showSprintManagementDialog() {
    final List<String> sprints = ['Sprint 1', 'Sprint 2', 'Sprint 3', 'Current Sprint'];
    String selectedSprint = 'Current Sprint';
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Sprint Management'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Active Sprint:', style: TextStyle(fontWeight: FontWeight.bold)),
                DropdownButton<String>(
                  value: selectedSprint,
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        selectedSprint = newValue;
                      });
                    }
                  },
                  items: sprints.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                const Text('Sprint Details:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                _buildSprintInfoRow('Start Date:', '2023-10-15'),
                _buildSprintInfoRow('End Date:', '2023-10-29'),
                _buildSprintInfoRow('Story Points:', '34/45'),
                _buildSprintInfoRow('Completion:', '75%'),
                const SizedBox(height: 16),
                const Text('Team Members:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    _buildTeamMemberChip('Alex'),
                    _buildTeamMemberChip('Maria'),
                    _buildTeamMemberChip('John'),
                    _buildTeamMemberChip('Sarah'),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sprint details updated')),
                );
                Navigator.of(context).pop();
              },
              child: const Text('Update Sprint'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSprintInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
  
  Widget _buildTeamMemberChip(String name) {
    return Chip(
      label: Text(name),
      avatar: CircleAvatar(
        child: Text(name[0]),
      ),
    );
  }

  void _showAllDeliverablesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('All Deliverables'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: [
              _buildDeliverableItem('Project Requirements Document', 'Completed', Colors.green),
              _buildDeliverableItem('System Architecture Design', 'Completed', Colors.green),
              _buildDeliverableItem('Database Schema', 'Completed', Colors.green),
              _buildDeliverableItem('Frontend Prototype', 'In Progress', Colors.orange),
              _buildDeliverableItem('API Documentation', 'In Progress', Colors.orange),
              _buildDeliverableItem('User Testing Report', 'Not Started', Colors.grey),
              _buildDeliverableItem('Deployment Guide', 'Not Started', Colors.grey),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Deliverables exported to PDF')),
              );
              Navigator.of(context).pop();
            },
            child: const Text('Export to PDF'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDeliverableItem(String name, String status, Color statusColor) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(name),
        subtitle: Text('Due: November 30, 2023'),
        trailing: Chip(
          label: Text(status),
          backgroundColor: statusColor.withOpacity(0.2),
          labelStyle: TextStyle(color: statusColor),
        ),
        onTap: () {
          // View deliverable details
        },
      ),
    );
  }

  void _showDeliverableDetailsDialog(Deliverable deliverable) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(deliverable.title),
        content: Text(deliverable.description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _navigateToProfile() {
    context.go('/profile');
  }

  void _handleLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              context.go('/');
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

}
