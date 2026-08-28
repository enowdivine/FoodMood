import 'package:flutter/material.dart';

import '../models/question.dart';
import '../theme/app_theme.dart';
import '../widgets/option_tile.dart';
import '../widgets/wordmark.dart';

/// One question at a time.
///
/// The header — wordmark, progress and prompt — is pinned; only the answers
/// scroll, so the user never loses sight of what they are answering. The view
/// owns the selection rules and hands the parent a finished set.
class OnboardingView extends StatefulWidget {
  const OnboardingView({
    required this.question,
    required this.stepIndex,
    required this.stepCount,
    required this.selected,
    required this.onChanged,
    required this.onNext,
    required this.onBack,
    super.key,
  });

  final Question question;
  final int stepIndex;
  final int stepCount;
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  final VoidCallback onNext;
  final VoidCallback onBack;

  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  /// Keeps free-text answers short enough to stay a sane prompt fragment.
  static const int _maxCustomLength = 40;

  late final TextEditingController _controller;

  /// The typed value currently held in the selection, so it can be swapped out
  /// as the user edits rather than accumulating every keystroke.
  String _customValue = '';

  bool _isCustomOpen = false;

  @override
  void initState() {
    super.initState();
    // Returning via Back should restore whatever was typed.
    final custom = widget.selected
        .where((value) => !widget.question.options.contains(value))
        .join(', ');
    _customValue = custom;
    _isCustomOpen = custom.isNotEmpty;
    _controller = TextEditingController(text: custom);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isLastStep => widget.stepIndex == widget.stepCount - 1;

  bool get _isOptional => widget.question.allowsMultiple;

  bool get _canContinue => _isOptional || widget.selected.isNotEmpty;

  void _togglePreset(String option) {
    final next = <String>{...widget.selected};

    if (widget.question.allowsMultiple) {
      next.contains(option) ? next.remove(option) : next.add(option);
    } else {
      // Single-select replaces everything, including any typed value.
      next
        ..clear()
        ..add(option);
      _customValue = '';
      _controller.clear();
      _isCustomOpen = false;
    }

    setState(() {});
    widget.onChanged(next);
  }

  void _openCustom() {
    setState(() => _isCustomOpen = true);
  }

  void _onCustomChanged(String raw) {
    final value = raw.trim();
    final next = <String>{...widget.selected};

    // Swap the previous typed value for the new one.
    if (_customValue.isNotEmpty) next.remove(_customValue);
    if (!widget.question.allowsMultiple) next.clear();
    if (value.isNotEmpty) next.add(value);

    _customValue = value;
    setState(() {});
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final question = widget.question;

    return SizedBox.expand(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pinned header.
          const SizedBox(height: AppTheme.gapSm),
          const Wordmark(),
          const SizedBox(height: AppTheme.gapLg),
          Text(
            'Question ${widget.stepIndex + 1} of ${widget.stepCount}',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: AppTheme.gapSm),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: (widget.stepIndex + 1) / widget.stepCount,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppTheme.gapLg),
          Text(question.prompt, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            question.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppTheme.gapMd),

          // Scrolling answers.
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: AppTheme.gapSm),
              children: [
                for (final option in question.options)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppTheme.gapSm),
                    child: OptionTile(
                      label: option,
                      selected: widget.selected.contains(option),
                      multiSelect: question.allowsMultiple,
                      onTap: () => _togglePreset(option),
                    ),
                  ),
                OptionTile(
                  label: 'Something else',
                  selected: _customValue.isNotEmpty,
                  multiSelect: question.allowsMultiple,
                  onTap: _openCustom,
                ),
                if (_isCustomOpen) ...[
                  const SizedBox(height: AppTheme.gapSm),
                  TextField(
                    controller: _controller,
                    autofocus: true,
                    maxLength: _maxCustomLength,
                    textInputAction: TextInputAction.done,
                    onChanged: _onCustomChanged,
                    onSubmitted: (_) {
                      if (_canContinue) widget.onNext();
                    },
                    decoration: InputDecoration(
                      hintText: _hintFor(question),
                      counterText: '',
                      border: OutlineInputBorder(
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusControl),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Pinned footer.
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppTheme.gapMd),
            child: Row(
              children: [
                if (widget.stepIndex > 0)
                  TextButton(
                    onPressed: widget.onBack,
                    child: const Text('Back'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: _canContinue ? widget.onNext : null,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 18,
                    ),
                  ),
                  child: Text(
                    _isLastStep
                        ? 'Find meals'
                        : (_isOptional && widget.selected.isEmpty
                            ? 'Skip'
                            : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A hint written for whichever question is on screen.
  String _hintFor(Question question) {
    if (question.options.contains('Vegan')) {
      return 'e.g. keto, halal, low FODMAP';
    }
    if (question.options.contains('Comforting')) {
      return 'e.g. nostalgic, celebratory';
    }
    if (question.options.contains('Bring the fire')) {
      return 'e.g. only black pepper';
    }
    if (question.options.contains('Shellfish')) {
      return 'e.g. sesame, pork, cilantro';
    }
    return 'Tell us in a few words';
  }
}
