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

    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            'assets/Icons/khono_bg.png',
            fit: BoxFit.cover,
          ),
        ),
        // Content
        child,
      ],
    );
  }
}
