import 'package:flutter/material.dart';

class QaEngineerDashboard extends StatelessWidget {
  const QaEngineerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QA Engineer Dashboard'),
      ),
      body: const Center(
        child: Text('Welcome, QA Engineer!'),
      ),
    );
  }
}