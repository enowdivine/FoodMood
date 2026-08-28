import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Owns the app's light/dark preference and remembers it between visits.
///
/// Starts on [ThemeMode.system] so a first-time visitor gets whatever their OS
/// is set to; once they choose explicitly, that choice wins and is persisted.
class ThemeController extends ChangeNotifier {
  ThemeController({ThemeMode initial = ThemeMode.system}) : _mode = initial;

  static const String _storageKey = 'foodmood.theme.v1';

  ThemeMode _mode;

  ThemeMode get mode => _mode;

  /// Resolves 'system' against the platform so the toggle can show the icon for
  /// what is actually on screen.
  bool isDark(BuildContext context) => switch (_mode) {
        ThemeMode.dark => true,
        ThemeMode.light => false,
        ThemeMode.system =>
          MediaQuery.platformBrightnessOf(context) == Brightness.dark,
      };

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getString(_storageKey);
      _mode = switch (stored) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      };
      notifyListeners();
    } catch (_) {
      // A missing or unreadable preference just means 'follow the system'.
    }
  }

  Future<void> toggle(BuildContext context) async {
    _mode = isDark(context) ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, _mode.name);
    } catch (_) {
      // Persistence is a convenience; the in-memory choice stays correct.
    }
  }
}
