import 'package:flutter/material.dart';

// A global controller for theme mode
class ThemeController {
  // ValueNotifier allows widgets to listen for changes
  static final ValueNotifier<ThemeMode> themeMode = ValueNotifier(
    ThemeMode.light,
  );

  // Toggle between light and dark mode
  static void toggleTheme() {
    themeMode.value = themeMode.value == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
  }
}
