import 'package:flutter/material.dart';
import '../services/version_service.dart';

class FixedFooterVersionDisplay extends StatelessWidget {
  const FixedFooterVersionDisplay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 12,
      left: 14,
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: FutureBuilder<Map<String, dynamic>>(
            future: VersionService.getVersionDetailsFromAsset(),
            builder: (context, snapshot) {
              final version = snapshot.data?['version']?.toString() ??
                  VersionService.getVersionDetails()['version'].toString();
              return Text(
                version,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.72),
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.left,
              );
            },
          ),
        ),
      ),
    );
  }
}
