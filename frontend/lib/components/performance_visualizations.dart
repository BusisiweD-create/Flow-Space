// ignore_for_file: deprecated_member_use, unused_import

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../services/api_service.dart';

class PerformanceVisualizations extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  
  const PerformanceVisualizations({super.key, required this.dashboardData});
  
  @override
  Widget build(BuildContext context) {
    return _PerformanceVisualizationsContent(dashboardData: dashboardData);
  }
}

class _PerformanceVisualizationsContent extends StatelessWidget {
  final Map<String, dynamic> dashboardData;
  
  const _PerformanceVisualizationsContent({required this.dashboardData});
  
  Widget _buildVelocityChart() {
    final sprintStats = dashboardData['sprint_stats'] as List? ?? [];
    
    if (sprintStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No sprint data available for velocity chart'),
        ),
      );
    }
    
    final barGroups = sprintStats.asMap().entries.map((entry) {
      final stat = entry.value;
      final index = entry.key;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (stat['completed_points'] ?? 0).toDouble(),
            color: Colors.blue,
            width: 16,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Velocity Chart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBurndownChart() {
    final sprintStats = dashboardData['sprint_stats'] as List? ?? [];
    
    if (sprintStats.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No sprint data available for burndown chart'),
        ),
      );
    }
    
    final spots = sprintStats.asMap().entries.map((entry) {
      final stat = entry.value;
      final index = entry.key;
      return FlSpot(
        index.toDouble(),
        ((stat['planned_points'] ?? 0) - (stat['completed_points'] ?? 0)).toDouble(),
      );
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Burndown Chart',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.red,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildDefectMetrics() {
    final sprints = dashboardData['sprints'] as List? ?? [];
    
    if (sprints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No defect data available'),
        ),
      );
    }
    
    final defectData = sprints.where((sprint) => 
      (sprint['defects_opened'] ?? 0) > 0 || 
      (sprint['defects_closed'] ?? 0) > 0,
    ).toList();
    
    if (defectData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No defect metrics available'),
        ),
      );
    }
    
    final barGroups = defectData.asMap().entries.map((entry) {
      final sprint = entry.value;
      final index = entry.key;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: (sprint['defects_opened'] ?? 0).toDouble(),
            color: Colors.red,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: (sprint['defects_closed'] ?? 0).toDouble(),
            color: Colors.green,
            width: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Defect Metrics',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  barGroups: barGroups,
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  barTouchData: BarTouchData(enabled: false),
                  alignment: BarChartAlignment.spaceAround,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTestMetrics() {
    final sprints = dashboardData['sprints'] as List? ?? [];
    
    if (sprints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No test metrics available'),
        ),
      );
    }
    
    final testData = sprints.where((sprint) => 
      (sprint['test_pass_rate'] ?? 0) > 0,
    ).toList();
    
    if (testData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No test metrics available'),
        ),
      );
    }
    
    final spots = testData.asMap().entries.map((entry) {
      final sprint = entry.value;
      final index = entry.key;
      return FlSpot(
        index.toDouble(),
        (sprint['test_pass_rate']?.toDouble() ?? 0.0),
      );
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Pass Rate',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.blue,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCodeCoverageMetrics() {
    final sprints = dashboardData['sprints'] as List? ?? [];
    
    if (sprints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No code coverage data available'),
        ),
      );
    }
    
    final coverageData = sprints.where((sprint) => 
      (sprint['code_coverage'] ?? 0) > 0,
    ).toList();
    
    if (coverageData.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No code coverage metrics available'),
        ),
      );
    }
    
    final spots = coverageData.asMap().entries.map((entry) {
      final sprint = entry.value;
      final index = entry.key;
      return FlSpot(
        index.toDouble(),
        (sprint['code_coverage']?.toDouble() ?? 0.0),
      );
    }).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Code Coverage',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: Colors.green,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(show: false),
                    ),
                  ],
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQualityMetricsSummary() {
    final sprints = dashboardData['sprints'] as List? ?? [];
    
    if (sprints.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No quality metrics available'),
        ),
      );
    }
    
    final recentSprint = sprints.last;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quality Metrics Summary',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              childAspectRatio: 2.5,
              children: [
                _buildMetricTile('Test Pass Rate', '${recentSprint['test_pass_rate'] ?? 'N/A'}%', Colors.blue),
                _buildMetricTile('Code Coverage', '${recentSprint['code_coverage'] ?? 'N/A'}%', Colors.green),
                _buildMetricTile('Defects Opened', '${recentSprint['defects_opened'] ?? '0'}', Colors.orange),
                _buildMetricTile('Defects Closed', '${recentSprint['defects_closed'] ?? '0'}', Colors.red),
                _buildMetricTile('Escaped Defects', '${recentSprint['escaped_defects'] ?? '0'}', Colors.purple),
                _buildMetricTile('Code Review %', '${recentSprint['code_review_completion'] ?? '0'}%', Colors.teal),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMetricTile(String title, String value, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildQualityMetricsSummary(),
          const SizedBox(height: 16),
          _buildVelocityChart(),
          const SizedBox(height: 16),
          _buildBurndownChart(),
          const SizedBox(height: 16),
          _buildDefectMetrics(),
          const SizedBox(height: 16),
          _buildTestMetrics(),
          const SizedBox(height: 16),
          _buildCodeCoverageMetrics(),
        ],
      ),
    );
  }
}