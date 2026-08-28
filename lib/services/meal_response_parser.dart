import 'dart:convert';

import '../models/meal.dart';

/// Turns the model's raw text into typed meals.
///
/// Kept free of Flutter and http imports so it can be unit tested directly —
/// see test/meal_response_parser_test.dart.
abstract final class MealResponseParser {
  /// Matches an opening ```json / ``` fence or a closing ``` fence.
  static final RegExp _fence = RegExp(r'^\s*```[a-zA-Z]*\s*|\s*```\s*$');

  /// Number of cards the UI renders.
  static const int maxMeals = 5;

  /// Returns up to [maxMeals] meals, or an empty list if nothing usable can be
  /// recovered. Never throws.
  static List<Meal> parse(String raw) {
    final json = _isolateJson(raw);
    if (json.isEmpty) return const [];

    try {
      final decoded = jsonDecode(json);
      final list = _asList(decoded);
      if (list == null) return const [];

      return list
          .whereType<Map<String, dynamic>>()
          .map(Meal.fromJson)
          .where((meal) => meal.isRenderable)
          .take(maxMeals)
          .toList(growable: false);
    } on FormatException {
      return const [];
    }
  }

  /// Strips markdown fences and any prose the model wrapped around the array.
  static String _isolateJson(String raw) {
    var text = raw.replaceAll(_fence, '').trim();
    if (text.startsWith('[')) return text;

    // The model sometimes prefaces the array with a sentence; take the
    // outermost bracket pair and discard the rest.
    final start = text.indexOf('[');
    final end = text.lastIndexOf(']');
    if (start != -1 && end > start) return text.substring(start, end + 1);

    return text.startsWith('{') ? text : '';
  }

  /// Accepts a bare array, or an object wrapping one under a common key.
  static List<dynamic>? _asList(dynamic decoded) {
    if (decoded is List) return decoded;
    if (decoded is Map<String, dynamic>) {
      for (final key in const ['meals', 'suggestions', 'results']) {
        final value = decoded[key];
        if (value is List) return value;
      }
    }
    return null;
  }
}
