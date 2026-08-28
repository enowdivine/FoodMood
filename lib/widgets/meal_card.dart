import 'package:flutter/material.dart';

import '../models/meal.dart';
import '../services/favourites_scope.dart';
import '../theme/app_theme.dart';
import 'meal_photo.dart';

class MealCard extends StatelessWidget {
  const MealCard({required this.meal, this.onTap, super.key});

  final Meal meal;

  /// Opens the full recipe. Null renders the card as a plain summary.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final radius = BorderRadius.circular(AppTheme.radiusCard);

    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: radius,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              MealPhoto(name: meal.name, width: 64, height: 64, radius: 14),
              const SizedBox(width: AppTheme.gapMd),
              Expanded(
                child: Text(
                  meal.name,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ),
              ListenableBuilder(
                listenable: FavouritesScope.of(context),
                builder: (context, _) {
                  final saved = FavouritesScope.of(context).contains(meal);
                  return IconButton(
                    onPressed: () => FavouritesScope.of(context).toggle(meal),
                    visualDensity: VisualDensity.compact,
                    tooltip: saved ? 'Remove from saved' : 'Save this meal',
                    icon: Icon(
                      saved ? Icons.bookmark : Icons.bookmark_border,
                      size: 20,
                      color: saved ? scheme.primary : scheme.outline,
                    ),
                  );
                },
              ),
            ],
          ),
          if (meal.why.isNotEmpty) ...[
            const SizedBox(height: AppTheme.gapSm),
            Text(
              meal.why,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.gapMd),
          Row(
            children: [
              if (meal.cookTime.isNotEmpty)
                _CookTimeChip(cookTime: meal.cookTime),
              const Spacer(),
              if (onTap != null)
                Text(
                  'View recipe',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                  ),
                ),
            ],
          ),
        ],
      ),
        ),
      ),
    );
  }
}

class _CookTimeChip extends StatelessWidget {
  const _CookTimeChip({required this.cookTime});

  final String cookTime;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 15, color: scheme.onPrimaryContainer),
          const SizedBox(width: AppTheme.gapXs),
          Text(
            cookTime,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
