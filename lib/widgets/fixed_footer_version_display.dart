import 'package:flutter/material.dart';
import '../services/version_service.dart';

class FixedFooterVersionDisplay extends StatelessWidget {
  const FixedFooterVersionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    final versionInfo = VersionService.getVersionDetails();
    final version = versionInfo['version'].toString();

    return Positioned(
      bottom: 12,
      left: 14,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            version,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.72),
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.left,
          ),
        ),
      ),
    );
  }
}
