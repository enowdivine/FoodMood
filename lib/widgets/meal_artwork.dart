import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Stand-in imagery for a dish: a deterministic gradient plus an icon inferred
/// from the dish name.
///
/// A real product would use photography, but that needs an image API and a
/// second key. This keeps every card visual, offline, instant, and stable —
/// the same meal always renders the same way.
class MealArtwork extends StatelessWidget {
  const MealArtwork({
    required this.name,
    this.size = 56,
    this.width,
    this.height,
    this.radius = 14,
    this.variant = 0,
    super.key,
  });

  final String name;

  /// Convenience for square panels; [width]/[height] override it.
  final double size;
  final double? width;
  final double? height;
  final double radius;

  /// Shifts the gradient so several panels for one dish differ from each other.
  final int variant;

  /// Keyword → icon, first match wins. Ordered from specific to general.
  static const Map<String, IconData> _icons = {
    'soup': Icons.soup_kitchen,
    'stew': Icons.soup_kitchen,
    'broth': Icons.soup_kitchen,
    'ramen': Icons.ramen_dining,
    'noodle': Icons.ramen_dining,
    'pasta': Icons.dinner_dining,
    'spaghetti': Icons.dinner_dining,
    'curry': Icons.rice_bowl,
    'rice': Icons.rice_bowl,
    'bowl': Icons.rice_bowl,
    'salad': Icons.local_florist,
    'pizza': Icons.local_pizza,
    'burger': Icons.lunch_dining,
    'sandwich': Icons.lunch_dining,
    'taco': Icons.lunch_dining,
    'wrap': Icons.lunch_dining,
    'egg': Icons.egg_alt,
    'omelette': Icons.egg_alt,
    'pancake': Icons.breakfast_dining,
    'toast': Icons.breakfast_dining,
    'porridge': Icons.breakfast_dining,
    'oat': Icons.breakfast_dining,
    'cake': Icons.cake,
    'smoothie': Icons.local_drink,
    'juice': Icons.local_drink,
    'fish': Icons.set_meal,
    'salmon': Icons.set_meal,
    'prawn': Icons.set_meal,
    'chicken': Icons.kebab_dining,
    'beef': Icons.kebab_dining,
    'lamb': Icons.kebab_dining,
    'skewer': Icons.kebab_dining,
    'grill': Icons.outdoor_grill,
    'roast': Icons.outdoor_grill,
    'bake': Icons.bakery_dining,
    'bread': Icons.bakery_dining,
  };

  IconData get _icon {
    final haystack = name.toLowerCase();
    for (final entry in _icons.entries) {
      if (haystack.contains(entry.key)) return entry.value;
    }
    return Icons.restaurant;
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.artworkFor('$name${'*' * variant}');
    final box = height ?? size;

    return Container(
      width: width ?? size,
      height: box,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(_icon, size: box * 0.42, color: Colors.white),
    );
  }
}
