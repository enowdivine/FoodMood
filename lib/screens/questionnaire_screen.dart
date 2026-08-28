import 'package:flutter/material.dart';

import '../data/onboarding_questions.dart';
import '../models/suggestion_result.dart';
import '../models/suggestion_run.dart';
import '../models/user_preferences.dart';
import '../services/favourites_scope.dart';
import '../services/meal_suggestion_service.dart';
import '../services/history_scope.dart';
import '../theme/app_theme.dart';
import '../widgets/theme_toggle_button.dart';
import 'favourites_screen.dart';
import 'history_screen.dart';
import 'loading_view.dart';
import 'onboarding_view.dart';
import 'results_view.dart';

/// Where the questionnaire currently is.
enum _Stage { onboarding, loading, results }

/// Owns the whole flow. The state here is small and short-lived — a stage, a
/// step index, and the answers — so a plain [StatefulWidget] is the right tool;
/// a state management package would add indirection without buying anything.
class QuestionnaireScreen extends StatefulWidget {
  const QuestionnaireScreen({
    super.key,
    this.service,
    this.resumeLastResult = false,
    this.run,
    this.preset,
  });

  /// Skips the questions entirely and asks immediately with these answers.
  final UserPreferences? preset;

  /// Opens straight on the most recent suggestions instead of question one.
  final bool resumeLastResult;

  /// Reopens a specific past run from history.
  final SuggestionRun? run;

  /// Injectable for tests; production builds use the default service.
  final MealSuggestionService? service;

  @override
  State<QuestionnaireScreen> createState() => _QuestionnaireScreenState();
}

class _QuestionnaireScreenState extends State<QuestionnaireScreen> {
  late final MealSuggestionService _service =
      widget.service ?? MealSuggestionService();

  /// One ordered set per question; single-select questions hold at most one.
  final List<Set<String>> _answers = List<Set<String>>.generate(
    kOnboardingQuestions.length,
    (_) => <String>{},
    growable: false,
  );

  _Stage _stage = _Stage.onboarding;
  int _step = 0;
  SuggestionResult? _result;
  UserPreferences? _preferences;

  /// The user's own words from the results search box, if they used it.
  String? _query;

  bool _prefilled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_stage == _Stage.onboarding) _prefillFromHistory();
  }

  /// Prefills the questions with the last run's answers, once, so a returning
  /// user tweaks rather than retypes. Their own choices override everything.
  void _prefillFromHistory() {
    if (_prefilled || widget.preset != null || widget.run != null) return;
    _prefilled = true;

    final latest = HistoryScope.of(context).latest;
    if (latest == null) return;

    setState(() => _answers.setAll(0, answersFrom(latest.preferences)));
  }

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    if (preset != null) {
      _preferences = preset;
      _answers.setAll(0, answersFrom(preset));
      _stage = _Stage.loading;
      // Scopes are not readable until the tree is built.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _submit();
      });
      return;
    }

    final run = widget.run;
    if (run != null) {
      _result = run.result;
      _preferences = run.preferences;
      _query = run.query;
      _stage = _Stage.results;
      return;
    }

    // Deferred: inherited widgets are not available during initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !widget.resumeLastResult) return;

      final latest = HistoryScope.of(context).latest;
      if (latest == null) return;

      setState(() {
        _result = latest.result;
        _preferences = latest.preferences;
        _query = latest.query;
        _stage = _Stage.results;
      });
    });
  }

  /// Back steps through the questions. It is not offered on the results stage:
  /// leaving from there used to discard the suggestions and force the whole
  /// questionnaire again, so results are left with explicit actions instead.
  void _handleBackButton() {
    if (_stage == _Stage.onboarding && _step > 0) {
      _back();
      return;
    }
    Navigator.of(context).maybePop();
  }

  /// Returns to question one with the answers cleared, staying in the flow.
  void _restart() {
    setState(() {
      _stage = _Stage.onboarding;
      _step = 0;
      _result = null;
      _preferences = null;
      _query = null;
      for (final answer in _answers) {
        answer.clear();
      }
    });
  }

  void _select(Set<String> chosen) =>
      setState(() => _answers[_step] = chosen);

  void _next() {
    if (_step < kOnboardingQuestions.length - 1) {
      setState(() => _step++);
    } else {
      _preferences = preferencesFrom(_answers);
      _submit();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _submit({String? query}) async {
    final preferences = _preferences ?? preferencesFrom(_answers);

    // Read the stores before the await; context is not safe to use after one.
    final history = HistoryScope.of(context);
    final favourites = FavouritesScope.of(context);
    setState(() {
      _preferences = preferences;
      _query = query;
      _stage = _Stage.loading;
    });

    final result = await _service.fetch(
      preferences,
      request: query,
      exclude: history.recentDishNames(),
      liked: favourites.savedNames,
    );
    if (!mounted) return;

    // Only real suggestions are worth keeping; fallbacks would fill history
    // with the same three recipes.
    if (mounted && !result.usedFallback) {
      history.add(
        SuggestionRun(
          createdAt: DateTime.now(),
          preferences: preferences,
          meals: result.meals,
          query: query,
        ),
      );
    }

    setState(() {
      _result = result;
      _stage = _Stage.results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: _stage == _Stage.results
            ? null
            : BackButton(onPressed: _handleBackButton),
        automaticallyImplyLeading: _stage != _Stage.results,
        actions: const [
          _HistoryAction(),
          ThemeToggleButton(),
          _SavedAction(),
          SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: AppTheme.contentMaxWidth,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.gapLg,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildStage(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case _Stage.onboarding:
        return OnboardingView(
          key: ValueKey('step-$_step'),
          question: kOnboardingQuestions[_step],
          stepIndex: _step,
          stepCount: kOnboardingQuestions.length,
          selected: _answers[_step],
          onChanged: _select,
          onNext: _next,
          onBack: _back,
        );
      case _Stage.loading:
        return const LoadingView(key: ValueKey('loading'));
      case _Stage.results:
        final result = _result;
        final preferences = _preferences;
        if (result == null || preferences == null) {
          return const LoadingView(key: ValueKey('loading'));
        }
        return ResultsView(
          key: ValueKey('results-${_query ?? ''}'),
          result: result,
          preferences: preferences,
          onRegenerate: () => _submit(query: _query),
          onRestart: _restart,
          onSearch: (query) => _submit(query: query),
          query: _query,
        );
    }
  }
}

/// Entry point to saved meals, with a live count. Present throughout the flow
/// so a user who saved something earlier can always get back to it.
class _SavedAction extends StatelessWidget {
  const _SavedAction();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: FavouritesScope.of(context),
      builder: (context, _) {
        final count = FavouritesScope.of(context).meals.length;

        return TextButton.icon(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const FavouritesScreen()),
          ),
          icon: const Icon(Icons.bookmark_border, size: 18),
          label: Text(count == 0 ? 'Saved' : 'Saved ($count)'),
        );
      },
    );
  }
}

/// Opens past searches from inside the flow, so a user looking at results can
/// switch to a different set of answers without starting over.
class _HistoryAction extends StatelessWidget {
  const _HistoryAction();

  @override
  Widget build(BuildContext context) {
    if (HistoryScope.of(context).isEmpty) return const SizedBox.shrink();

    return IconButton(
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const HistoryScreen()),
      ),
      tooltip: 'Recent searches',
      icon: const Icon(Icons.history, size: 20),
    );
  }
}
