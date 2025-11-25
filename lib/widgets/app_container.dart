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
        image: DecorationImage(
          image: AssetImage('assets/Icons/Global BG.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        // ignore: deprecated_member_use
        color: Colors.black.withOpacity(0.7), // TODO: Replace with proper color value when withOpacity is removed
        child: child,
      ),
    );
  }
}
