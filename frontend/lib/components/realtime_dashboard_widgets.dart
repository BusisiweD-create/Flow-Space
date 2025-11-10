import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/dashboard_provider.dart';
import '../services/realtime_service.dart';

class RealtimeMetricsCard extends ConsumerWidget {
  final String title;
  final String valueKey;
  final IconData icon;
  final Color color;

  const RealtimeMetricsCard({
    super.key,
    required this.title,
    required this.valueKey,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final analyticsData = dashboardState.analyticsData;
    
    final value = analyticsData[valueKey]?.toString() ?? '0';
    return _buildCard(title, value, icon, color);
  }

  Widget _buildCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RealtimeConnectionStatus extends ConsumerWidget {
  const RealtimeConnectionStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = realtimeService.isConnected;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isConnected ? 'Connected' : 'Disconnected',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isConnected ? Colors.green : Colors.red,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isConnected
                        ? 'Real-time updates active'
                        : 'Check your connection',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
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
}

class RealtimeDashboard extends StatelessWidget {
  const RealtimeDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const RealtimeConnectionStatus(),
            const SizedBox(height: 16),
            
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: const [
                RealtimeMetricsCard(
                  title: 'Active Users',
                  valueKey: 'activeUsers',
                  icon: Icons.people,
                  color: Colors.blue,
                ),
                RealtimeMetricsCard(
                  title: 'Completed Tasks',
                  valueKey: 'completedTasks',
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                RealtimeMetricsCard(
                  title: 'Pending Tasks',
                  valueKey: 'pendingTasks',
                  icon: Icons.pending,
                  color: Colors.orange,
                ),
                RealtimeMetricsCard(
                  title: 'Online Team',
                  valueKey: 'teamMembersOnline',
                  icon: Icons.group,
                  color: Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}