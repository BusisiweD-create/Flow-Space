import 'package:flutter/material.dart';
import '../models/sprint.dart';

class SprintReportScreen extends StatelessWidget {
  final List<Sprint> sprints;

  const SprintReportScreen({super.key, required this.sprints});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sprint Report'),
      ),
      body: ListView.builder(
        itemCount: sprints.length,
        itemBuilder: (context, index) {
          final sprint = sprints[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sprint.name, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8.0),
                  Text('Status: ${sprint.statusText}'),
                  const SizedBox(height: 8.0),
                  Text('Committed Points: ${sprint.committedPoints}'),
                  const SizedBox(height: 8.0),
                  Text('Completed Points: ${sprint.completedPoints}'),
                  const SizedBox(height: 8.0),
                  LinearProgressIndicator(
                    value: sprint.committedPoints > 0 ? sprint.completedPoints / sprint.committedPoints : 0,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}