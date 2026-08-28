import 'package:flutter/material.dart';

import '../services/theme_scope.dart';

/// Switches between light and dark, showing the mode you would move to.
class ThemeToggleButton extends StatelessWidget {
  const ThemeToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeScope.of(context);
    final isDark = controller.isDark(context);

    return IconButton(
      onPressed: () => controller.toggle(context),
      tooltip: isDark ? 'Switch to light' : 'Switch to dark',
      icon: Icon(
        isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
        size: 20,
      ),
    );
  }
}
