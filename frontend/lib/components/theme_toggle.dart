// ignore_for_file: deprecated_member_use, use_super_parameters

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/theme_provider.dart';

class ThemeToggle extends ConsumerWidget {
  final bool showLabel;
  final EdgeInsetsGeometry? padding;
  final double? iconSize;

  const ThemeToggle({
    super.key,
    this.showLabel = true,
    this.padding,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return IconButton(
      icon: _getThemeIcon(themeMode),
      onPressed: () => themeNotifier.toggleTheme(),
      tooltip: 'Toggle theme (${themeNotifier.themeName})',
      padding: padding ?? const EdgeInsets.all(8.0),
      iconSize: iconSize ?? 24.0,
    );
  }

  Widget _getThemeIcon(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return const Icon(Icons.brightness_auto);
      case ThemeMode.light:
        return const Icon(Icons.brightness_high);
      case ThemeMode.dark:
        return const Icon(Icons.brightness_2);
    }
  }
}

class ThemeToggleWithLabel extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;

  const ThemeToggleWithLabel({
    super.key,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);

    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Theme',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          DropdownButton<ThemeMode>(
            value: themeMode,
            onChanged: (ThemeMode? newMode) {
              if (newMode != null) {
                if (newMode == ThemeMode.system) {
                  themeNotifier.setSystemTheme();
                } else {
                  themeNotifier.setTheme(newMode == ThemeMode.dark);
                }
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Row(
                  children: [
                    Icon(Icons.brightness_auto, size: 20),
                    SizedBox(width: 8),
                    Text('System'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Row(
                  children: [
                    Icon(Icons.brightness_high, size: 20),
                    SizedBox(width: 8),
                    Text('Light'),
                  ],
                ),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Row(
                  children: [
                    Icon(Icons.brightness_2, size: 20),
                    SizedBox(width: 8),
                    Text('Dark'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ThemeAwareIcon extends ConsumerWidget {
  final IconData lightIcon;
  final IconData darkIcon;
  final double? size;
  final Color? color;

  const ThemeAwareIcon({
    super.key,
    required this.lightIcon,
    required this.darkIcon,
    this.size,
    this.color,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider.notifier).isDarkMode;
    
    return Icon(
      isDarkMode ? darkIcon : lightIcon,
      size: size,
      color: color,
    );
  }
}

class ThemeAwareText extends ConsumerWidget {
  final String text;
  final TextStyle? lightStyle;
  final TextStyle? darkStyle;
  final TextStyle? style;
  final StrutStyle? strutStyle;
  final TextAlign? textAlign;
  final TextDirection? textDirection;
  final Locale? locale;
  final bool? softWrap;
  final TextOverflow? overflow;
  final double? textScaleFactor;
  final int? maxLines;
  final String? semanticsLabel;
  final TextWidthBasis? textWidthBasis;
  final TextHeightBehavior? textHeightBehavior;

  const ThemeAwareText(
    this.text, {
    super.key,
    this.lightStyle,
    this.darkStyle,
    this.style,
    this.strutStyle,
    this.textAlign,
    this.textDirection,
    this.locale,
    this.softWrap,
    this.overflow,
    this.textScaleFactor,
    this.maxLines,
    this.semanticsLabel,
    this.textWidthBasis,
    this.textHeightBehavior,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(themeProvider.notifier).isDarkMode;
    
    return Text(
      text,
      style: (isDarkMode ? darkStyle : lightStyle) ?? style,
      strutStyle: strutStyle,
      textAlign: textAlign,
      textDirection: textDirection,
      locale: locale,
      softWrap: softWrap,
      overflow: overflow,
      textScaleFactor: textScaleFactor,
      maxLines: maxLines,
      semanticsLabel: semanticsLabel,
      textWidthBasis: textWidthBasis,
      textHeightBehavior: textHeightBehavior,
    );
  }
}