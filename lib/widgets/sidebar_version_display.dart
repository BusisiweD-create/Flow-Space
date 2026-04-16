import 'package:flutter/material.dart';
import '../services/version_service.dart';
import 'package:google_fonts/google_fonts.dart';

class SidebarVersionDisplay extends StatelessWidget {
  final bool isSidebarCollapsed;

  const SidebarVersionDisplay({
    super.key,
    this.isSidebarCollapsed = false,
  });

  @override
  Widget build(BuildContext context) {
    // Only show version when sidebar is expanded
    if (isSidebarCollapsed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: FutureBuilder<Map<String, dynamic>>(
        future: VersionService.getVersionDetailsFromAsset(),
        builder: (context, snapshot) {
          final version = snapshot.data?['version']?.toString() ??
              VersionService.getVersionDetails()['version'].toString();
          return Text(
            version,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.65),
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        },
      ),
    );
  }
}
