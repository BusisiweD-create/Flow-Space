import 'package:flutter/material.dart';

import '../../theme/flownet_theme.dart';
import 'glass_panel.dart';

/// Reusable glass search bar for repository, lists, and filters.
class GlassSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hintText;

  const GlassSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.hintText = 'Search...',
  });

  @override
  Widget build(BuildContext context) {
    return GlassPanel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      borderRadius: 24,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: FlownetColors.pureWhite),
        decoration: const InputDecoration(
          border: InputBorder.none,
          hintText: 'Search...',
          hintStyle: TextStyle(
            color: FlownetColors.coolGray,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: FlownetColors.coolGray,
          ),
        ),
      ),
    );
  }
}


