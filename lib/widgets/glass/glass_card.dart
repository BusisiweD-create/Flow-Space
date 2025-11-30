import 'package:flutter/material.dart';

import '../../theme/flownet_theme.dart';
import 'glass_panel.dart';

/// Glass card for dashboards, lists, and content sections.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin = const EdgeInsets.symmetric(vertical: 8),
    this.borderRadius = 24,
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: padding,
      margin: margin,
      borderRadius: borderRadius,
      child: child,
    );
  }
}


