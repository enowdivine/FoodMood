import '../models/question.dart';
import '../models/user_preferences.dart';

/// The three questions, in order. Adding a fourth needs no UI changes — the
/// screen drives itself off this list's length — but [preferencesFrom] below
/// is the one place that would need updating.
const List<Question> kOnboardingQuestions = [
  Question(
    prompt: 'Which meal is this for?',
    subtitle: 'Breakfast and dinner deserve different answers.',
    options: [
      'Breakfast',
      'Lunch',
      'Dinner',
      'Snack',
    ],
  ),
  Question(
    prompt: 'How do you eat?',
    subtitle: 'Every suggestion will stay inside this.',
    options: [
      'Anything',
      'Vegetarian',
      'Vegan',
      'Pescatarian',
      'High protein',
    ],
  ),
  Question(
    prompt: 'What is the mood?',
    subtitle: 'Cooking energy matters as much as taste.',
    options: [
      'Comforting',
      'Light and fresh',
      'Fast and lazy',
      'Adventurous',
      'Impress someone',
    ],
  ),
  Question(
    prompt: 'How much heat?',
    subtitle: 'Be honest, nobody is watching.',
    options: [
      'None',
      'Mild',
      'Medium',
      'Hot',
      'Bring the fire',
    ],
  ),
  Question(
    prompt: 'Anything to avoid?',
    subtitle: 'Pick as many as apply. We keep all of them out.',
    allowsMultiple: true,
    options: [
      'Nuts',
      'Dairy',
      'Gluten',
      'Shellfish',
      'Eggs',
    ],
  ),
];

/// Maps positional answers onto the typed value object the service consumes.
///
/// Multi-select answers arrive as several strings and are joined, which is the
/// form the prompt wants anyway.
UserPreferences preferencesFrom(List<Set<String>> answers) {
  String at(int index, String fallback) {
    if (index >= answers.length) return fallback;
    final chosen = answers[index].where((value) => value.trim().isNotEmpty);
    return chosen.isEmpty ? fallback : chosen.join(', ');
  }

  return UserPreferences(
    mealType: at(0, 'Dinner'),
    diet: at(1, 'Anything'),
    mood: at(2, 'Comforting'),
    spice: at(3, 'Mild'),
    avoid: at(4, 'Nothing'),
  );
}

/// The inverse of [preferencesFrom]: seeds the questionnaire from a previous
/// run, so a returning user edits their last answers instead of retyping them.
List<Set<String>> answersFrom(UserPreferences preferences) {
  Set<String> split(String value) => value
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty && part.toLowerCase() != 'nothing')
      .toSet();

  return [
    {preferences.mealType},
    {preferences.diet},
    {preferences.mood},
    {preferences.spice},
    split(preferences.avoid),
  ];
}
