import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final EdgeInsetsGeometry? padding;
  final Gradient? gradient;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 12.0,
    this.blur = 10.0,
    this.color,
    this.border,
    this.boxShadow,
    this.padding,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            color: color ?? Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(borderRadius),
            border: border ?? Border.all(
              color: Colors.white.withAlpha(26),
              width: 1.0,
            ),
            boxShadow: boxShadow ?? [
              BoxShadow(
                color: Colors.black.withAlpha(26),
                blurRadius: blur,
                spreadRadius: 1,
              ),
            ],
            gradient: gradient,
          ),
          child: child,
        ),
      ),
    );
  }
}