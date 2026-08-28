import 'package:flutter/foundation.dart';

import 'meal.dart';
import 'suggestion_result.dart';
import 'user_preferences.dart';

/// One completed round of suggestions: what was asked, what came back, when.
///
/// This is what history is made of, and the most recent entry doubles as
/// "your last suggestions" on the welcome screen.
@immutable
class SuggestionRun {
  const SuggestionRun({
    required this.createdAt,
    required this.preferences,
    required this.meals,
    this.query,
  });

  factory SuggestionRun.fromJson(Map<String, dynamic> json) => SuggestionRun(
        createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        preferences: UserPreferences.fromJson(
          json['preferences'] as Map<String, dynamic>? ?? const {},
        ),
        meals: (json['meals'] as List? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(Meal.fromJson)
            .where((meal) => meal.isRenderable)
            .toList(growable: false),
        query: json['query'] as String?,
      );

  final DateTime createdAt;
  final UserPreferences preferences;
  final List<Meal> meals;

  /// The free-text request behind this run, if the user searched.
  final String? query;

  bool get isRenderable => meals.isNotEmpty;

  /// What the user asked for, in one line.
  String get label =>
      (query != null && query!.isNotEmpty) ? '"$query"' : preferences.summary;

  /// Re-opening a run shows exactly what it returned, as live results.
  SuggestionResult get result => SuggestionResult.live(meals);

  Map<String, dynamic> toJson() => {
        'createdAt': createdAt.toIso8601String(),
        'preferences': preferences.toJson(),
        'meals': meals.map((meal) => meal.toJson()).toList(),
        'query': query,
      };
}
