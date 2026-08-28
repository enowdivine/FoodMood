import 'package:flutter/material.dart';

/// Single source of truth for the app's visual language.
abstract final class AppTheme {
  /// Warm orange — appetite-adjacent, and the seed for the whole M3 scheme.
  static const Color seed = Color(0xFFF97316);

  /// Deeper end of the brand gradient, used in the wordmark.
  static const Color seedDeep = Color(0xFFEA580C);

  /// Shared spacing scale, so padding never gets invented at the call site.
  static const double gapXs = 6;
  static const double gapSm = 10;
  static const double gapMd = 16;
  static const double gapLg = 24;
  static const double gapXl = 40;

  /// Reading width for the single-column layout.
  static const double contentMaxWidth = 560;

  static const double radiusCard = 18;
  static const double radiusControl = 14;

  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: brightness,
        ),
        useMaterial3: true,
      );

  /// Deterministic gradient for a dish, so the same meal always looks the same
  /// between sessions without shipping or fetching any images.
  static List<Color> artworkFor(String name) {
    const palettes = [
      [Color(0xFFF97316), Color(0xFFDB2777)],
      [Color(0xFFEA580C), Color(0xFFCA8A04)],
      [Color(0xFF16A34A), Color(0xFF0D9488)],
      [Color(0xFF7C3AED), Color(0xFFDB2777)],
      [Color(0xFF0284C7), Color(0xFF7C3AED)],
      [Color(0xFFDC2626), Color(0xFFEA580C)],
    ];
    final hash = name.codeUnits.fold<int>(0, (sum, unit) => sum + unit);
    return palettes[hash % palettes.length];
  }
}
