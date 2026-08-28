import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/suggestion_run.dart';

/// Persistence for suggestion history, abstracted so tests run without
/// platform channels.
abstract interface class HistoryStorage {
  Future<String?> read();

  Future<void> write(String value);
}

class SharedPreferencesHistoryStorage implements HistoryStorage {
  const SharedPreferencesHistoryStorage();

  static const String _storageKey = 'foodmood.history.v1';

  @override
  Future<String?> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_storageKey);
  }

  @override
  Future<void> write(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, value);
  }
}

/// Every round of suggestions the user has run, newest first.
///
/// This is also where "your last suggestions" comes from — [latest] — so a
/// reload, or leaving the results screen, never loses what they were looking
/// at, and there is only one place this data is stored.
class HistoryStore extends ChangeNotifier {
  HistoryStore({
    HistoryStorage storage = const SharedPreferencesHistoryStorage(),
  }) : _storage = storage;

  final HistoryStorage _storage;

  /// Enough to be useful, few enough to keep the payload and the list small.
  static const int maxEntries = 20;

  List<SuggestionRun> _runs = const [];

  List<SuggestionRun> get runs => List.unmodifiable(_runs);

  SuggestionRun? get latest => _runs.isEmpty ? null : _runs.first;

  bool get isEmpty => _runs.isEmpty;

  Future<void> load() async {
    try {
      final raw = await _storage.read();
      if (raw == null || raw.isEmpty) return;

      final json = jsonDecode(raw);
      if (json is! List) return;

      _runs = json
          .whereType<Map<String, dynamic>>()
          .map(SuggestionRun.fromJson)
          .where((run) => run.isRenderable)
          .toList();
      notifyListeners();
    } catch (_) {
      _runs = const [];
    }
  }

  /// Dish names already suggested recently, newest first.
  ///
  /// Fed back into the prompt so a regenerate returns new ideas instead of
  /// reshuffling the same ones. Capped because the point is to steer the model,
  /// not to hand it an essay.
  List<String> recentDishNames({int limit = 15}) => _runs
      .expand((run) => run.meals.map((meal) => meal.name))
      .toSet()
      .take(limit)
      .toList(growable: false);

  Future<void> add(SuggestionRun run) async {
    if (!run.isRenderable) return;

    _runs = [run, ..._runs].take(maxEntries).toList();
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _runs = const [];
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        jsonEncode(_runs.map((run) => run.toJson()).toList()),
      );
    } catch (_) {
      // Persistence is a convenience; the in-memory list stays correct.
    }
  }
}
