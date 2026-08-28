import 'package:flutter/foundation.dart';

import 'meal.dart';

/// The outcome of a suggestion request.
///
/// There is deliberately no error variant: every failure path resolves to the
/// fallback meals plus a [notice], so the UI has exactly one shape to render
/// and the user never sees a stack trace.
@immutable
class SuggestionResult {
  const SuggestionResult.live(this.meals)
      : usedFallback = false,
        notice = null;

  const SuggestionResult.fallback(this.meals, this.notice)
      : usedFallback = true;

  factory SuggestionResult.fromJson(Map<String, dynamic> json) {
    final meals = (json['meals'] as List? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(Meal.fromJson)
        .where((meal) => meal.isRenderable)
        .toList();
    final notice = json['notice'] as String?;

    return notice == null
        ? SuggestionResult.live(meals)
        : SuggestionResult.fallback(meals, notice);
  }

  Map<String, dynamic> toJson() => {
        'meals': meals.map((meal) => meal.toJson()).toList(),
        'notice': notice,
      };

  final List<Meal> meals;
  final bool usedFallback;

  /// Plain-language explanation of why these are fallback meals, or null.
  final String? notice;
}
