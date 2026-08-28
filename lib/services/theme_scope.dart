import 'package:flutter/widgets.dart';

import 'theme_controller.dart';

/// Provides the app's [ThemeController] to the widgets below it.
class ThemeScope extends InheritedNotifier<ThemeController> {
  const ThemeScope({
    required ThemeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static ThemeController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<ThemeScope>();
    assert(scope != null, 'No ThemeScope found in the widget tree');
    return scope!.notifier!;
  }
}
