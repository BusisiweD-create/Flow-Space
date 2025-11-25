import 'package:flutter/material.dart';

class AppContainer extends StatelessWidget {
  final Widget child;
  final bool showBackground;

  const AppContainer({
    super.key,
    required this.child,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBackground) {
      return child;
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Dark background color
      ),
      child: child,
    );
  }
}
