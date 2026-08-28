import 'package:flutter/foundation.dart';

/// A single meal suggestion, whether it came from the model or the fallback.
@immutable
class Meal {
  const Meal({
    required this.name,
    required this.why,
    required this.cookTime,
    this.servings = '',
    this.difficulty = '',
    this.ingredients = const [],
    this.steps = const [],
  });

  /// Builds a [Meal] from one element of the model's JSON array.
  ///
  /// The model is free-running text generation, so key spelling drifts between
  /// responses ("cook_time" vs "cookTime" vs "time"). We accept the known
  /// variants and fall back to empty rather than throwing — a partial card
  /// still beats a failed screen.
  factory Meal.fromJson(Map<String, dynamic> json) {
    String readString(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is String && value.trim().isNotEmpty) return value.trim();
        if (value is num) return value.toString();
      }
      return '';
    }

    List<String> readList(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value is List) {
          final items = value
              .map((item) => item is String ? item.trim() : item.toString())
              .where((item) => item.isNotEmpty)
              .toList(growable: false);
          if (items.isNotEmpty) return items;
        }
      }
      return const [];
    }

    return Meal(
      name: readString(const ['name', 'meal', 'title']),
      why: readString(const ['why', 'why_it_fits', 'whyItFits', 'reason']),
      cookTime: readString(const ['cook_time', 'cookTime', 'time', 'duration']),
      servings: readString(const ['servings', 'serves', 'yield']),
      difficulty: readString(const ['difficulty', 'level']),
      ingredients: readList(const ['ingredients', 'items']),
      steps: readList(const ['steps', 'method', 'instructions', 'directions']),
    );
  }

  final String name;
  final String why;
  final String cookTime;
  final String servings;
  final String difficulty;
  final List<String> ingredients;
  final List<String> steps;

  /// A meal with no name has nothing to render; the parser drops these.
  bool get isRenderable => name.isNotEmpty;

  /// True when the model returned enough for a useful recipe page.
  bool get hasRecipe => ingredients.isNotEmpty || steps.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'name': name,
        'why': why,
        'cook_time': cookTime,
        'servings': servings,
        'difficulty': difficulty,
        'ingredients': ingredients,
        'steps': steps,
      };

  @override
  bool operator ==(Object other) => other is Meal && other.name == name;

  @override
  int get hashCode => name.hashCode;
}
