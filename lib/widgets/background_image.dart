import 'dart:ui';

import 'package:flutter/material.dart';

class BackgroundImage extends StatelessWidget {
  final Widget child;
  final String imagePath;
  final BoxFit fit;
  final bool withGlassEffect;
  final double overlayOpacity;  // Should be between 0.0 and 1.0
  final bool withGradient;
  final AlignmentGeometry gradientBegin;
  final AlignmentGeometry gradientEnd;
  final List<Color>? gradientColors;
  final double blurRadius;
  final Widget? overlayChild;

  const BackgroundImage({
    super.key,
    required this.child,
    this.imagePath = 'assets/Icons/khono_bg.png',
    this.fit = BoxFit.cover,
    this.withGlassEffect = true,
    this.overlayOpacity = 0.3,
    this.withGradient = true,
    this.gradientBegin = Alignment.topCenter,
    this.gradientEnd = Alignment.bottomCenter,
    this.gradientColors,
    this.blurRadius = 5.0,
    this.overlayChild,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: fit,
            // Render background sharply
            filterQuality: FilterQuality.high,
          ),
        ),
        
        // Gradient overlay
        if (withGradient)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: gradientBegin,
                  end: gradientEnd,
                  colors: gradientColors ?? [
                    Colors.transparent,
                    Colors.black.withAlpha((0.7 * 255).round()),  // 0.7 * 255 ≈ 179
                  ],
                ),
              ),
            ),
          ),
        
        // Semi-transparent overlay
        Positioned.fill(
          child: Container(
            color: Colors.black.withAlpha((overlayOpacity * 255).round()),
            child: withGlassEffect
                ? Stack(
                    children: [
                      // Frosted glass effect
                      if (withGlassEffect) ...[  
                        BackdropFilter(
                          filter: ImageFilter.blur(
                            sigmaX: blurRadius,
                            sigmaY: blurRadius,
                          ),
                          child: Container(
                            color: Colors.transparent,
                          ),
                        ),
                        // Subtle noise texture
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha((0.02 * 255).round()),  // 0.02 * 255 ≈ 5
                            backgroundBlendMode: BlendMode.overlay,
                          ),
                        ),
                      ],
                      // Child content
                      if (overlayChild != null) overlayChild! else child,
                    ],
                  )
                : child,
          ),
        ),
      ],
    );
  }
}

// Extension for easy access to the background image in any build method
extension BackgroundImageExtension on Widget {
  Widget withBackground({
    String imagePath = 'assets/Icons/khono_bg.png',
    BoxFit fit = BoxFit.cover,
    bool withGlassEffect = true,
    double overlayOpacity = 0.3,
    bool withGradient = true,
    AlignmentGeometry gradientBegin = Alignment.topCenter,
    AlignmentGeometry gradientEnd = Alignment.bottomCenter,
    List<Color>? gradientColors,
    double blurRadius = 5.0,
    Widget? overlayChild,
  }) {
    return BackgroundImage(
      imagePath: imagePath,
      fit: fit,
      withGlassEffect: withGlassEffect,
      overlayOpacity: overlayOpacity,
      withGradient: withGradient,
      gradientBegin: gradientBegin,
      gradientEnd: gradientEnd,
      gradientColors: gradientColors,
      blurRadius: blurRadius,
      overlayChild: overlayChild,
      child: this,
    );
  }
}
