import 'package:flutter/material.dart';
import 'glass_card.dart';

class ProjectCard extends StatelessWidget {
  final Map<String, dynamic> project;
  final bool isSelected;
  final VoidCallback onTap;

  const ProjectCard({
    super.key,
    required this.project,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final surfaceColor = theme.colorScheme.surface;
    final onSurfaceColor = theme.colorScheme.onSurface;
    final String? startDateStr = project['start_date']?.toString();
    final String? endDateStr = project['end_date']?.toString();

    String formatDate(String? value) {
      if (value == null || value.isEmpty) return '';
      try {
        final date = DateTime.parse(value);
        return '${date.day}/${date.month}/${date.year}';
      } catch (_) {
        return value;
      }
    }
    
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        color: isSelected 
            ? primaryColor.withAlpha(51)  // 0.2 * 255 ≈ 51
            : surfaceColor.withAlpha(128),  // 0.5 * 255 = 128
        border: Border.all(
          color: isSelected 
              ? primaryColor 
              : onSurfaceColor.withAlpha(26),  // 0.1 * 255 ≈ 26
          width: isSelected ? 2 : 1,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryColor.withAlpha(51),  // 0.2 * 255 ≈ 51
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.folder,
                    color: primaryColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    project['name'] ?? 'Unknown',
                    style: TextStyle(
                      color: onSurfaceColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              project['key'] ?? '',
              style: TextStyle(
                color: onSurfaceColor.withAlpha(179),  // 0.7 * 255 ≈ 179
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              project['project_type'] ?? 'software',
              style: TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            if (startDateStr != null || endDateStr != null)
              Text(
                '${formatDate(startDateStr).isNotEmpty ? formatDate(startDateStr) : 'No start date'}'
                ' - '
                '${formatDate(endDateStr).isNotEmpty ? formatDate(endDateStr) : 'No end date'}',
                style: TextStyle(
                  color: onSurfaceColor.withAlpha(179),
                  fontSize: 11,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
