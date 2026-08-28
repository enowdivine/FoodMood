import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../services/favourites_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_photo.dart';
import 'favourites_screen.dart';

/// The full recipe for one suggestion, plus the save toggle.
class MealDetailScreen extends StatelessWidget {
  const MealDetailScreen({required this.meal, super.key});

  final Meal meal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          ListenableBuilder(
            listenable: FavouritesScope.of(context),
            builder: (context, _) {
              final count = FavouritesScope.of(context).meals.length;
              if (count == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const FavouritesScreen(),
                  ),
                ),
                child: Text('Saved ($count)'),
              );
            },
          ),
          ListenableBuilder(
            listenable: FavouritesScope.of(context),
            builder: (context, _) {
              final saved = FavouritesScope.of(context).contains(meal);
              return IconButton(
                onPressed: () => FavouritesScope.of(context).toggle(meal),
                tooltip: saved ? 'Remove from saved' : 'Save this meal',
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  color: saved ? scheme.primary : null,
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.gapLg,
                0,
                AppTheme.gapLg,
                AppTheme.gapXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MealPhoto(
                    name: meal.name,
                    height: 190,
                    radius: AppTheme.radiusCard,
                  ),
                  const SizedBox(height: AppTheme.gapSm),
                  Row(
                    children: [
                      for (var variant = 1; variant <= 3; variant++) ...[
                        if (variant > 1) const SizedBox(width: AppTheme.gapSm),
                        Expanded(
                          child: MealPhoto(
                            name: meal.name,
                            variant: variant,
                            height: 84,
                            radius: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppTheme.gapLg),
                  Text(
                    meal.name,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  if (meal.why.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.gapSm),
                    Text(
                      meal.why,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                        height: 1.55,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.gapLg),
                  Wrap(
                    spacing: AppTheme.gapSm,
                    runSpacing: AppTheme.gapSm,
                    children: [
                      if (meal.cookTime.isNotEmpty)
                        _Stat(icon: Icons.schedule, label: meal.cookTime),
                      if (meal.servings.isNotEmpty)
                        _Stat(
                          icon: Icons.people_outline,
                          label: 'Serves ${meal.servings}',
                        ),
                      if (meal.difficulty.isNotEmpty)
                        _Stat(
                          icon: Icons.local_fire_department_outlined,
                          label: meal.difficulty,
                        ),
                    ],
                  ),
                  if (meal.ingredients.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const _SectionHeading(title: 'Ingredients'),
                    const SizedBox(height: AppTheme.gapSm),
                    for (final ingredient in meal.ingredients)
                      _BulletRow(text: ingredient),
                  ],
                  if (meal.steps.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const _SectionHeading(title: 'Method'),
                    const SizedBox(height: AppTheme.gapSm),
                    for (final (index, step) in meal.steps.indexed)
                      _StepRow(number: index + 1, text: step),
                  ],
                  if (!meal.hasRecipe) ...[
                    const SizedBox(height: 32),
                    Text(
                      'The model did not return a full recipe for this one. '
                      'Regenerate the suggestions to try again.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            letterSpacing: 1.1,
          ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppTheme.gapXs),
          Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.number, required this.text});

  final int number;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.gapMd),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: scheme.secondaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.55),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
