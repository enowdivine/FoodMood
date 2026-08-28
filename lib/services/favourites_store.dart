import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/meal.dart';

/// Where saved meals are kept. Abstracted so tests can run without platform
/// channels, and so swapping local storage for an account-backed API later is
/// one class rather than a rewrite.
abstract interface class FavouritesStorage {
  Future<List<String>> read();

  Future<void> write(List<String> entries);
}

/// Production implementation: the browser's local storage on web.
class SharedPreferencesStorage implements FavouritesStorage {
  const SharedPreferencesStorage();

  static const String _storageKey = 'foodmood.favourites.v1';

  @override
  Future<List<String>> read() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_storageKey) ?? const [];
  }

  @override
  Future<void> write(List<String> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_storageKey, entries);
  }
}

/// Saved meals, persisted through [FavouritesStorage].
///
/// A [ChangeNotifier] rather than a state management package: this is the one
/// piece of state that outlives a screen. The instance is created in `main`
/// and passed down through [FavouritesScope], so tests can build a widget tree
/// around their own store instead of reaching for a global.
class FavouritesStore extends ChangeNotifier {
  FavouritesStore({FavouritesStorage storage = const SharedPreferencesStorage()})
      : _storage = storage;

  final FavouritesStorage _storage;

  List<Meal> _meals = const [];

  List<Meal> get meals => List.unmodifiable(_meals);

  bool get isEmpty => _meals.isEmpty;

  bool contains(Meal meal) => _meals.contains(meal);

  /// Names of saved meals, as a signal of what this user actually likes.
  List<String> get savedNames =>
      _meals.map((meal) => meal.name).toList(growable: false);

  /// Loads persisted favourites. Failures are non-fatal — a corrupt or absent
  /// store simply starts the user with an empty list.
  Future<void> load() async {
    try {
      final raw = await _storage.read();
      _meals = raw
          .map((entry) => jsonDecode(entry))
          .whereType<Map<String, dynamic>>()
          .map(Meal.fromJson)
          .where((meal) => meal.isRenderable)
          .toList();
      notifyListeners();
    } catch (_) {
      _meals = const [];
    }
  }

  Future<void> toggle(Meal meal) async {
    _meals = contains(meal)
        ? (_meals.where((saved) => saved != meal).toList())
        : ([..._meals, meal]);
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _storage.write(
        _meals.map((meal) => jsonEncode(meal.toJson())).toList(),
      );
    } catch (_) {
      // Persistence is a convenience; the in-memory list stays correct.
    }
  }
}
