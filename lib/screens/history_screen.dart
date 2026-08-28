import 'package:flutter/material.dart';

import '../models/suggestion_run.dart';
import '../services/history_scope.dart';
import '../theme/app_theme.dart';
import '../utils/relative_time.dart';
import '../widgets/meal_photo.dart';
import '../widgets/theme_toggle_button.dart';
import 'questionnaire_screen.dart';

/// Past rounds of suggestions, newest first, so a good set can be reopened
/// without answering the questions again.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  /// Reopens exactly what that run returned.
  void _open(BuildContext context, SuggestionRun run) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => QuestionnaireScreen(run: run)),
    );
  }

  /// Re-asks the model with that run's answers, skipping the questions, so a
  /// past set of preferences becomes a fresh set of suggestions.
  void _reuse(BuildContext context, SuggestionRun run) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => QuestionnaireScreen(preset: run.preferences),
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context) async {
    final store = HistoryScope.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear history?'),
        content: const Text(
          'This removes your past suggestions. Saved meals are not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed ?? false) await store.clear();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final runs = HistoryScope.of(context).runs;

    return Scaffold(
      backgroundColor: scheme.surface,
      appBar: AppBar(
        title: const Text('Recent searches'),
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (runs.isNotEmpty)
            IconButton(
              onPressed: () => _confirmClear(context),
              tooltip: 'Clear history',
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          const ThemeToggleButton(),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: runs.isEmpty
                ? _Empty(scheme: scheme, theme: theme)
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.gapLg),
                    itemCount: runs.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.gapSm),
                    itemBuilder: (context, index) => _RunTile(
                      run: runs[index],
                      onTap: () => _open(context, runs[index]),
                      onReuse: () => _reuse(context, runs[index]),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.scheme, required this.theme});

  final ColorScheme scheme;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppTheme.gapLg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 40, color: scheme.outline),
          const SizedBox(height: AppTheme.gapMd),
          Text('No searches yet', style: theme.textTheme.titleMedium),
          const SizedBox(height: AppTheme.gapXs),
          Text(
            'Every set of suggestions you run shows up here.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RunTile extends StatelessWidget {
  const _RunTile({
    required this.run,
    required this.onTap,
    required this.onReuse,
  });

  final SuggestionRun run;
  final VoidCallback onTap;
  final VoidCallback onReuse;

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
          padding: const EdgeInsets.all(AppTheme.gapMd),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(color: scheme.outlineVariant),
          ),
          child: Row(
            children: [
              MealPhoto(
                name: run.meals.first.name,
                width: 52,
                height: 52,
                radius: 12,
              ),
              const SizedBox(width: AppTheme.gapMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      run.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${run.meals.length} ideas · '
                      '${formatRelative(run.createdAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onReuse,
                tooltip: 'New ideas with these answers',
                icon: Icon(Icons.refresh, size: 20, color: scheme.primary),
              ),
              Icon(Icons.chevron_right, color: scheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}
