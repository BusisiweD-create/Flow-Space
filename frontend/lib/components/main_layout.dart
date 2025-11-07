// ignore_for_file: unused_import, use_super_parameters, sort_child_properties_last, require_trailing_commas

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import './sidebar.dart';

final sidebarProvider = StateProvider<bool>((ref) => false);

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String currentRoute;

  const MainLayout({
    Key? key,
    required this.child,
    required this.currentRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSidebarCollapsed = ref.watch(sidebarProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Sidebar(
            isCollapsed: isSidebarCollapsed,
            onToggle: (collapsed) {
              ref.read(sidebarProvider.notifier).state = collapsed;
            },
            currentRoute: currentRoute,
          ),
          // Main content
          Expanded(
            child: Column(
              children: [
                // App bar for mobile view
                if (MediaQuery.of(context).size.width < 768)
                  AppBar(
                    title: const Text('Khonology'),
                    leading: IconButton(
                      icon: const Icon(Icons.menu),
                      onPressed: () {
                        ref.read(sidebarProvider.notifier).state = 
                            !ref.read(sidebarProvider);
                      },
                    ),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                  ),
                // Main content area
                Expanded(child: child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Helper function to wrap screens with main layout
Widget wrapWithLayout(Widget child, String route) {
  return Consumer(builder: (context, ref, _) {
    return MainLayout(child: child, currentRoute: route);
  });
}