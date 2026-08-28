import '../models/meal.dart';

/// Shown whenever a live suggestion cannot be produced: no API key, network
/// failure, non-200, timeout, or unparseable output.
///
/// Chosen to be broadly acceptable — one omnivore, one plant-based, one fast —
/// so the list stays plausible regardless of what the user answered.
const List<Meal> kFallbackMeals = [
  Meal(
    name: 'One-pan lemon herb chicken and rice',
    why: 'A forgiving weeknight staple that suits almost any palate — mild, '
        'filling, and everything cooks in a single pan.',
    cookTime: '35 min',
    servings: '4',
    difficulty: 'Easy',
    ingredients: [
      '4 chicken thighs, bone in',
      '1 cup long grain rice',
      '2 cups chicken stock',
      '1 lemon, zested and juiced',
      '2 cloves garlic, sliced',
      'Handful of parsley',
      'Olive oil, salt, pepper',
    ],
    steps: [
      'Season the chicken and brown it skin-side down in an oven-safe pan.',
      'Lift the chicken out, soften the garlic in the fat, then stir in rice.',
      'Add stock and lemon juice, settle the chicken back on top.',
      'Cover and bake at 190C for 25 minutes until the rice drinks the stock.',
      'Rest 5 minutes, then finish with lemon zest and parsley.',
    ],
  ),
  Meal(
    name: 'Coconut chickpea curry',
    why: 'Plant-based, gently spiced, and built from pantry tins. Scale the '
        'chilli up or down without touching the rest of the recipe.',
    cookTime: '25 min',
    servings: '3',
    difficulty: 'Easy',
    ingredients: [
      '2 tins chickpeas, drained',
      '1 tin coconut milk',
      '1 onion, diced',
      '2 tbsp curry powder',
      'Thumb of ginger, grated',
      '2 handfuls spinach',
      'Rice or flatbread to serve',
    ],
    steps: [
      'Soften the onion in oil until translucent, about 6 minutes.',
      'Add ginger and curry powder and fry until fragrant.',
      'Pour in coconut milk and chickpeas, simmer 12 minutes.',
      'Wilt the spinach through at the end and season to taste.',
    ],
  ),
  Meal(
    name: 'Garlic butter noodles with greens',
    why: 'Ready before a delivery order would arrive, and comforting without '
        'being heavy. Add whatever vegetable is in the fridge.',
    cookTime: '15 min',
    servings: '2',
    difficulty: 'Very easy',
    ingredients: [
      '200g noodles',
      '3 tbsp butter',
      '4 cloves garlic, thinly sliced',
      '2 tbsp soy sauce',
      'Any green vegetable, chopped',
      'Chilli flakes to finish',
    ],
    steps: [
      'Boil the noodles, adding the greens for the last two minutes.',
      'Melt butter with the garlic over low heat until just golden.',
      'Toss the drained noodles through the butter with the soy sauce.',
      'Finish with chilli flakes and a splash of the noodle water.',
    ],
  ),
];
