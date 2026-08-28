import 'package:flutter/material.dart';

import '../models/suggestion_result.dart';
import '../models/user_preferences.dart';
import '../theme/app_theme.dart';
import '../widgets/meal_card.dart';
import '../widgets/notice_banner.dart';
import '../widgets/wordmark.dart';
import 'meal_detail_screen.dart';

class ResultsView extends StatefulWidget {
  const ResultsView({
    required this.result,
    required this.preferences,
    required this.onRegenerate,
    required this.onRestart,
    required this.onSearch,
    this.query,
    super.key,
  });

  final SuggestionResult result;
  final UserPreferences preferences;
  final VoidCallback onRegenerate;

  /// Returns to question one without leaving the flow.
  final VoidCallback onRestart;

  /// Asks again in the user's own words when the suggestions miss.
  final ValueChanged<String> onSearch;

  /// The request these results answered, if any.
  final String? query;

  @override
  State<ResultsView> createState() => _ResultsViewState();
}

class _ResultsViewState extends State<ResultsView> {
  late final TextEditingController _searchController =
      TextEditingController(text: widget.query ?? '');

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch() {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    FocusScope.of(context).unfocus();
    widget.onSearch(query);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppTheme.gapXl),
          const Wordmark(),
          const SizedBox(height: 32),
          Text(
            widget.query?.isNotEmpty ?? false
                ? 'Ideas for "${widget.query}"'
                : '${widget.preferences.mealType} ideas',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            widget.preferences.summary,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (widget.result.notice case final notice?) ...[
            const SizedBox(height: 20),
            NoticeBanner(message: notice),
          ],
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
            decoration: InputDecoration(
              hintText: 'Not these? Ask for something specific',
              prefixIcon: const Icon(Icons.search, size: 20),
              suffixIcon: IconButton(
                onPressed: _submitSearch,
                icon: const Icon(Icons.arrow_forward, size: 20),
                tooltip: 'Search',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              ),
            ),
          ),
          const SizedBox(height: 20),
          for (final meal in widget.result.meals)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: MealCard(
                meal: meal,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => MealDetailScreen(meal: meal),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: widget.onRegenerate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('Five more'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.gapMd,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.gapSm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onRestart,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Start over'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppTheme.gapMd,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.gapXl),
        ],
      ),
    );
  }
}
