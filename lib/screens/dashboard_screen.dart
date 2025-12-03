import 'package:flutter/material.dart';
import '../theme/flownet_theme.dart';
import '../widgets/app_scaffold.dart';
import '../widgets/background_image.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardNotifierProvider.notifier).loadDashboardData();
    });
  }
class MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String change;
  final bool isIncrease;

  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color = Colors.blue,
    this.change = '+0%',
    this.isIncrease = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 26),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isIncrease ? Colors.green.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isIncrease ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 14,
                        color: isIncrease ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        change,
                        style: TextStyle(
                          color: isIncrease ? Colors.green : Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color = FlownetColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 51), // 20% opacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: SprintPerformanceChart(sprints: dashboardState.sprints.map((sprint) {
                return {
                  'id': sprint.id,
                  'name': sprint.name,
                  'start_date': sprint.startDate.toIso8601String(),
                  'end_date': sprint.endDate.toIso8601String(),
                  'planned_points': sprint.committedPoints,
                  'completed_points': sprint.completedPoints,
                  'status': 'completed',
                };
              }).toList(),),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverablesSection(DashboardState dashboardState) {
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
        if (dashboardState.deliverables.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                const Icon(Icons.assignment, size: 48, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No deliverables yet',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Create your first deliverable to get started',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...dashboardState.deliverables.take(5).map((deliverable) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DeliverableCard(
                  deliverable: deliverable,
                  onTap: () {
                    context.go('/report-editor/${deliverable.id}');
                  },
                ),
              ),),
      ],
    );
  }

  void _showCreateDeliverableDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Deliverable'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Choose the type of deliverable setup:'),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.speed),
              title: const Text('Quick Setup'),
              subtitle: const Text('Basic deliverable creation'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/deliverable-setup');
              },
            ),
            ListTile(
              leading: const Icon(Icons.engineering),
              title: const Text('Enhanced Setup'),
              subtitle: const Text('Full DoD, evidence, and readiness check'),
              onTap: () {
                Navigator.of(context).pop();
                context.go('/enhanced-deliverable-setup');
              },
}

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: FlownetColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlownetColors.primary.withValues(alpha: 51), // 20% opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bar_chart,
                color: FlownetColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: FlownetColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Here\'s what\'s happening with your projects',
                    style: TextStyle(
                      color: FlownetColors.textSecondary,
                      fontSize: 14,
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

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notifications'),
        content: const Text('No new notifications.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset(
            'assets/Icons/khono.png',
            width: 40,
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.grey),
            onPressed: _showNotifications,
          ),
          const CircleAvatar(
            backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=User&background=random'),
            radius: 16,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: BackgroundImage(
        imagePath: 'assets/Icons/khono_bg.png',
        withGlassEffect: false,
        overlayOpacity: 0.25,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Welcome back! Here\'s what\'s happening with your projects.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 24),
                // Stats Grid
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: const [
                    MetricCard(
                      title: 'Total Revenue',
                      value: '\$12,345',
                      icon: Icons.attach_money,
                      color: Colors.blue,
                      change: '+12%',
                      isIncrease: true,
                    ),
                    MetricCard(
                      title: 'Active Users',
                      value: '1,234',
                      icon: Icons.people,
                      color: Colors.green,
                      change: '+5%',
                      isIncrease: true,
                    ),
                    MetricCard(
                      title: 'New Orders',
                      value: '245',
                      icon: Icons.shopping_cart,
                      color: Colors.orange,
                      change: '-2%',
                      isIncrease: false,
                    ),
                    MetricCard(
                      title: 'Bounce Rate',
                      value: '12.5%',
                      icon: Icons.trending_up,
                      color: Colors.purple,
                      change: '+0.5%',
                      isIncrease: true,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Recent Orders
                Card(
                  elevation: 0,
                  color: Colors.black.withValues(alpha: 0.55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Recent Orders',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Add your recent orders list here
                        _buildOrderItem('Order #1234', 'Processing', '\$125.00'),
                        _buildOrderItem('Order #1233', 'Completed', '\$85.50'),
                        _buildOrderItem('Order #1232', 'Shipped', '\$215.00'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderItem(String orderNumber, String status, String amount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            orderNumber,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ),
        Text(
          status,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Settings'),
        content: const Text('Settings will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showSprintManagementDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sprint Management'),
        content: const Text('Sprint management details will be implemented in the next phase.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class InfoCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const InfoCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.color = FlownetColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.black.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 51), // 20% opacity
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: FlownetColors.surface.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: FlownetColors.primary.withValues(alpha: 51), // 20% opacity
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.bar_chart,
                color: FlownetColors.primary,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back!',
                    style: TextStyle(
                      color: FlownetColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Here\'s what\'s happening with your projects',
                    style: TextStyle(
                      color: FlownetColors.textSecondary,
                      fontSize: 14,
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