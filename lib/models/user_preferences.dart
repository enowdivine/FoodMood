import 'package:flutter/foundation.dart';

/// The three onboarding answers, resolved into a typed value object.
///
/// Keeping this separate from the questionnaire means the service never has to
/// know that answers arrived as a positional list of strings.
@immutable
class UserPreferences {
  const UserPreferences({
    required this.mealType,
    required this.diet,
    required this.mood,
    required this.spice,
    required this.avoid,
  });

  /// Breakfast, Lunch, Dinner or Snack.
  final String mealType;

  final String diet;
  final String mood;
  final String spice;

  /// Allergens to exclude entirely, comma separated, or 'Nothing'.
  final String avoid;

  /// True when the user named something that must never appear.
  bool get hasExclusion =>
      avoid.isNotEmpty && avoid.toLowerCase() != 'nothing';

  factory UserPreferences.fromJson(Map<String, dynamic> json) =>
      UserPreferences(
        mealType: json['mealType'] as String? ?? 'Dinner',
        diet: json['diet'] as String? ?? 'Anything',
        mood: json['mood'] as String? ?? 'Comforting',
        spice: json['spice'] as String? ?? 'Mild',
        avoid: json['avoid'] as String? ?? 'Nothing',
      );

  Map<String, dynamic> toJson() => {
        'mealType': mealType,
        'diet': diet,
        'mood': mood,
        'spice': spice,
        'avoid': avoid,
      };

  /// Human-readable summary shown above the results.
  String get summary => hasExclusion
      ? '$mealType · $diet · $mood · $spice · no $avoid'
      : '$mealType · $diet · $mood · $spice';
}
