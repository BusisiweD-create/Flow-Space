import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class SprintPerformanceChart extends StatelessWidget {
  final List<Map<String, dynamic>> sprints;
  final String chartType;

  const SprintPerformanceChart({
    super.key,
    required this.sprints,
    this.chartType = 'velocity',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _getChartTitle(),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Flexible(
              child: SizedBox(
                height: 200,
                child: _buildChart(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getChartTitle() {
    switch (chartType) {
      case 'velocity':
        return 'Velocity Trend';
      case 'burndown':
        return 'Burndown Chart';
      case 'burnup':
        return 'Burnup Chart';
      case 'defects':
        return 'Defect Trend';
      case 'test_pass_rate':
        return 'Test Pass Rate';
      default:
        return 'Performance Chart';
    }
  }

  Widget _buildChart() {
    switch (chartType) {
      case 'velocity':
        return _buildVelocityChart();
      case 'burndown':
        return _buildBurndownChart();
      case 'burnup':
        return _buildBurnupChart();
      case 'defects':
        return _buildDefectsChart();
      case 'test_pass_rate':
        return _buildTestPassRateChart();
      default:
        return _buildVelocityChart();
    }
  }

  Widget _buildVelocityChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < sprints.length; i++) {
      final sprint = sprints[i];
      spots.add(FlSpot(
        i.toDouble(),
        (sprint['completed_points'] ?? 0).toDouble(),
      ),);
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sprints.length) {
                  return Text('Sprint ${value.toInt() + 1}');
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.blue,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.blue.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBurndownChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < sprints.length; i++) {
      final sprint = sprints[i];
      final remaining = (sprint['planned_points'] ?? 0) - (sprint['completed_points'] ?? 0);
      spots.add(FlSpot(i.toDouble(), remaining.toDouble()));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sprints.length) {
                  return Text('Sprint ${value.toInt() + 1}');
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.red,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildBurnupChart() {
    final spots = <FlSpot>[];
    double cumulative = 0;
    for (int i = 0; i < sprints.length; i++) {
      final sprint = sprints[i];
      cumulative += (sprint['completed_points'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), cumulative));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sprints.length) {
                  return Text('Sprint ${value.toInt() + 1}');
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.green,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.green.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefectsChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < sprints.length; i++) {
      final sprint = sprints[i];
      // Use actual defect data from sprint
      final defectCount = (sprint['defects_opened'] ?? 0).toDouble();
      spots.add(FlSpot(i.toDouble(), defectCount));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sprints.length) {
                  return Text('Sprint ${value.toInt() + 1}');
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.orange,
            barWidth: 3,
            dotData: const FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  Widget _buildTestPassRateChart() {
    final spots = <FlSpot>[];
    for (int i = 0; i < sprints.length; i++) {
      final sprint = sprints[i];
      // Use actual test pass rate data from sprint
      final passRate = (sprint['test_pass_rate'] ?? 0.0).toDouble();
      spots.add(FlSpot(i.toDouble(), passRate));
    }

    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: true),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() < sprints.length) {
                  return Text('Sprint ${value.toInt() + 1}');
                }
                return const Text('');
              },
            ),
          ),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: Colors.purple,
            barWidth: 3,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: Colors.purple.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}

class SprintMetricsCard extends StatelessWidget {
  final Map<String, dynamic> sprint;

  const SprintMetricsCard({super.key, required this.sprint});

  @override
  Widget build(BuildContext context) {
    final plannedPoints = sprint['planned_points'] ?? 0;
    final completedPoints = sprint['completed_points'] ?? 0;
    final completionRate = plannedPoints > 0 ? (completedPoints / plannedPoints) : 0.0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sprint Metrics',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Planned Points',
                    plannedPoints.toString(),
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Completed Points',
                    completedPoints.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricItem(
                    'Completion Rate',
                    '${(completionRate * 100).toStringAsFixed(1)}%',
                    Icons.pie_chart,
                    _getCompletionColor(completionRate),
                  ),
                ),
                Expanded(
                  child: _buildMetricItem(
                    'Status',
                    sprint['status'] ?? 'Unknown',
                    Icons.flag,
                    _getStatusColor(sprint['status']),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: completionRate,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                _getCompletionColor(completionRate),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Color _getCompletionColor(double rate) {
    if (rate >= 1.0) return Colors.green;
    if (rate >= 0.8) return Colors.blue;
    if (rate >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'planning':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}