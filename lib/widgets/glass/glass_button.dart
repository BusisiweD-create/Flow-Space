import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/flownet_theme.dart';

/// Primary action button with glassmorphism styling.
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool isDestructive;

  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    this.borderRadius = 24,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color accent = isDestructive
        ? FlownetColors.crimsonRed
        : FlownetColors.electricBlue;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Material(
          color: Colors.white.withValues(alpha: 0.06),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Container(
              padding: padding,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(
                  color: accent.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.25),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: DefaultTextStyle.merge(
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.3,
                ),
                child: Center(child: child),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


