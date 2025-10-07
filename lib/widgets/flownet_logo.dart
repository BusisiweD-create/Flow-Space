import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/flownet_theme.dart';

class FlownetLogo extends StatefulWidget {
  final double? width;
  final double? height;
  final bool showText; // true = full logo, false = icon-only
  final VoidCallback? onTap;

  const FlownetLogo({
    super.key,
    this.width,
    this.height,
    this.showText = true,
    this.onTap,
  });

  @override
  State<FlownetLogo> createState() => _FlownetLogoState();
}

class _FlownetLogoState extends State<FlownetLogo> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final handleTap = widget.onTap ?? () => context.go('/dashboard');

    // When showText is false, we treat it as icon-only sizing
    final double targetHeight = widget.height ?? (widget.showText ? 40 : 32);
    final double targetWidth = widget.width ?? (widget.showText ? 140 : 32);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: handleTap,
        child: AnimatedScale(
          scale: _hovering ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.only(top: 24, bottom: 16), // pt-6 pb-4
            decoration: BoxDecoration(
              boxShadow: _hovering
                  ? [
                      BoxShadow(
                        color: FlownetColors.crimsonRed.withValues(alpha: 0.25),
                        blurRadius: 14,
                        spreadRadius: 1,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: targetWidth,
                height: targetHeight,
                child: widget.showText ? _buildFullLogo() : _buildIconOnly(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFullLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 3x3 Grid Logo
        _buildGridLogo(size: 20),
        const SizedBox(height: 2),
        // Text
        const Text(
          'FLOWNET',
          style: TextStyle(
            color: FlownetColors.crimsonRed,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.6,
          ),
        ),
        const Text(
          'WORKSPACES',
          style: TextStyle(
            color: FlownetColors.pureWhite,
            fontSize: 6,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildIconOnly() {
    return _buildGridLogo(size: 24);
  }

  Widget _buildGridLogo({required double size}) {
    return SizedBox(
      width: size,
      height: size,
      child: GridView.count(
        crossAxisCount: 3,
        mainAxisSpacing: 2,
        crossAxisSpacing: 2,
        children: [
          // Row 1
          _buildCircle(FlownetColors.crimsonRed),
          _buildCircle(FlownetColors.crimsonRed),
          _buildCircle(FlownetColors.crimsonRed),
          
          // Row 2
          _buildCircle(FlownetColors.crimsonRed),
          _buildCircle(FlownetColors.crimsonRed),
          _buildCircle(FlownetColors.crimsonRed),
          
          // Row 3
          _buildCircle(FlownetColors.crimsonRed),
          _buildCircle(FlownetColors.crimsonRed),
          _buildCircle(FlownetColors.pureWhite),
        ],
      ),
    );
  }

  Widget _buildCircle(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}