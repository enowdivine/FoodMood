import 'package:flutter/material.dart';

import '../services/favourites_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';
import '../widgets/theme_toggle_button.dart';
import 'meal_detail_screen.dart';

/// Meals the user chose to keep, restored from local storage.
class FavouritesScreen extends StatelessWidget {
  const FavouritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Saved meals'),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: const [ThemeToggleButton(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: ListenableBuilder(
              listenable: FavouritesScope.of(context),
              builder: (context, _) {
                final meals = FavouritesScope.of(context).meals;

                if (meals.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AppTheme.gapLg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bookmark_border,
                          size: 40,
                          color: scheme.outline,
                        ),
                        const SizedBox(height: AppTheme.gapMd),
                        Text(
                          'Nothing saved yet',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppTheme.gapXs),
                        Text(
                          'Open a suggestion and tap the bookmark to keep it.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(AppTheme.gapLg),
                  itemCount: meals.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppTheme.gapSm),
                  itemBuilder: (context, index) {
                    final meal = meals[index];
                    return MealCard(
                      meal: meal,
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => MealDetailScreen(meal: meal),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
