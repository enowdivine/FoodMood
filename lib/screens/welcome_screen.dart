import 'package:flutter/material.dart';

import '../services/favourites_scope.dart';
import '../services/history_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_toggle_button.dart';
import '../widgets/wordmark.dart';
import 'favourites_screen.dart';
import 'history_screen.dart';
import 'questionnaire_screen.dart';

/// The front door: what the app does, and one way in.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _start(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const QuestionnaireScreen()),
    );
  }

  void _repeatLast(BuildContext context) {
    final latest = HistoryScope.of(context).latest;
    if (latest == null) return;

    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionnaireScreen(preset: latest.preferences),
      ),
    );
  }

  void _resume(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const QuestionnaireScreen(resumeLastResult: true),
      ),
    );
  }

  void _openFavourites(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const FavouritesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.gapLg,
                vertical: AppTheme.gapXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Wordmark(size: WordmarkSize.large),
                      const Spacer(),
                      const ThemeToggleButton(),
                      ListenableBuilder(
                        listenable: FavouritesScope.of(context),
                        builder: (context, _) {
                          final count = FavouritesScope.of(context).meals.length;
                          return TextButton.icon(
                            onPressed: () => _openFavourites(context),
                            icon: const Icon(Icons.bookmark_border, size: 18),
                            label: Text(count == 0 ? 'Saved' : 'Saved ($count)'),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 56),
                  Text(
                    'What should\nyou cook next?',
                    style: theme.textTheme.displaySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: AppTheme.gapMd),
                  Text(
                    'Five quick questions — which meal, how you eat, your mood, '
                    'how much heat you can take and anything you avoid. We '
                    'will hand back five ideas worth making, with the recipe '
                    'for each.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 36),
                  const _Highlight(
                    icon: Icons.tune,
                    title: 'Built around you',
                    body: 'Meal, diet, mood, spice and allergies shape every '
                        'suggestion.',
                  ),
                  const SizedBox(height: AppTheme.gapMd),
                  const _Highlight(
                    icon: Icons.auto_awesome,
                    title: 'Written fresh each time',
                    body: 'Suggestions come from a live AI model, not a fixed '
                        'list.',
                  ),
                  const SizedBox(height: AppTheme.gapMd),
                  const _Highlight(
                    icon: Icons.bookmark_added_outlined,
                    title: 'Keep the good ones',
                    body: 'Save a meal and it stays put between visits.',
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _start(context),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                      ),
                      child: const Text('Find me something to cook'),
                    ),
                  ),
                  if (HistoryScope.of(context).latest case final latest?) ...[
                    const SizedBox(height: AppTheme.gapSm),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () => _repeatLast(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Column(
                          children: [
                            const Text('Same as last time'),
                            const SizedBox(height: 2),
                            Text(
                              latest.preferences.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppTheme.gapSm),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => _resume(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Back to your last suggestions'),
                      ),
                    ),
                  ],
                  if (HistoryScope.of(context).runs.length > 1) ...[
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const HistoryScreen(),
                          ),
                        ),
                        icon: const Icon(Icons.history, size: 18),
                        label: const Text('Recent searches'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppTheme.gapMd),
                  Center(
                    child: Text(
                      'Takes about twenty seconds.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 19, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: AppTheme.gapMd),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
