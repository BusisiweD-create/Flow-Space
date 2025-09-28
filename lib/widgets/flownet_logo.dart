import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
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

  Future<bool> _checkAssetExists(String assetPath) async {
    try {
      await rootBundle.load(assetPath);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<String?> _resolveAssetPath({required bool fullLogo}) async {
    final primary = fullLogo ? 'assets/logo.png' : 'assets/logo_icon.png';
    if (await _checkAssetExists(primary)) return primary;
    // Fallback: use full logo for collapsed state if icon isn't present
    const fallback = 'assets/logo.png';
    if (!fullLogo && await _checkAssetExists(fallback)) return fallback;
    return null;
  }

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
                        color: FlownetColors.crimsonRed.withOpacity(0.25),
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
                child: FutureBuilder<String?>(
                  future: _resolveAssetPath(fullLogo: widget.showText),
                  builder: (context, snapshot) {
                    final path = snapshot.data;
                    if (path != null) {
                      return ClipRRect(
                        borderRadius:
                            BorderRadius.circular(widget.showText ? 8 : 6),
                        child: Image.asset(
                          path,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      );
                    }
                    // Simple fallback if the asset is missing so the app still runs
                    return Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(widget.showText ? 8 : 6),
                        color: FlownetColors.graphiteGray,
                      ),
                      child: Icon(
                        Icons.blur_circular,
                        color: FlownetColors.crimsonRed,
                        size: widget.showText ? targetHeight * 0.8 : 20,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
