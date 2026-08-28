import 'package:flutter/foundation.dart';

/// One onboarding step: a prompt and its mutually exclusive answers.
@immutable
class Question {
  const Question({
    required this.prompt,
    required this.subtitle,
    required this.options,
    this.allowsMultiple = false,
  });

  final String prompt;
  final String subtitle;
  final List<String> options;

  /// True where several answers can be true at once, such as allergies.
  final bool allowsMultiple;
}
