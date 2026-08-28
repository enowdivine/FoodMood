import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodmood/data/fallback_meals.dart';
import 'package:foodmood/models/meal.dart';
import 'package:foodmood/models/suggestion_result.dart';
import 'package:foodmood/models/user_preferences.dart';
import 'package:foodmood/screens/favourites_screen.dart';
import 'package:foodmood/screens/history_screen.dart';
import 'package:foodmood/screens/questionnaire_screen.dart';
import 'package:foodmood/screens/results_view.dart';
import 'package:foodmood/screens/welcome_screen.dart';
import 'package:foodmood/services/favourites_scope.dart';
import 'package:foodmood/services/favourites_store.dart';
import 'package:foodmood/services/photo_scope.dart';
import 'package:foodmood/models/suggestion_run.dart';
import 'package:foodmood/services/history_scope.dart';
import 'package:foodmood/services/history_store.dart';
import 'package:foodmood/services/photo_service.dart';
import 'package:foodmood/services/theme_controller.dart';
import 'package:foodmood/services/theme_scope.dart';
import 'package:foodmood/theme/app_theme.dart';

/// In-memory storage so widget tests never touch platform channels.
class _FakeStorage implements FavouritesStorage {
  List<String> _entries = const [];

  @override
  Future<List<String>> read() async => _entries;

  @override
  Future<void> write(List<String> entries) async => _entries = entries;
}

/// Mirrors the scopes `FoodMoodApp` installs, so screens under test resolve
/// their dependencies exactly as they do in the running app.
/// In-memory history persistence, standing in for local storage.
class _FakeHistoryStorage implements HistoryStorage {
  String? value;

  @override
  Future<String?> read() async => value;

  @override
  Future<void> write(String entry) async => value = entry;
}

Widget _wrap(Widget child, FavouritesStore store, {HistoryStore? history}) {
  return PhotoScope(
    // A client that fails every request keeps tests off the network; widgets
    // fall back to their generated artwork, which is what we assert against.
    service: PhotoService(client: MockClient((_) async => http.Response('', 500))),
    child: HistoryScope(
      store: history ?? HistoryStore(storage: _FakeHistoryStorage()),
      child: FavouritesScope(
        store: store,
        child: ThemeScope(
          controller: ThemeController(),
          child: MaterialApp(theme: AppTheme.light, home: child),
        ),
      ),
    ),
  );
}

const _meal = Meal(
  name: 'Miso noodle soup',
  why: 'Warming and quick.',
  cookTime: '20 min',
  servings: '2',
  difficulty: 'Easy',
  ingredients: ['Miso paste', 'Noodles'],
  steps: ['Boil', 'Serve'],
);

void main() {
  testWidgets('welcome screen offers a way in and a way to saved meals',
      (tester) async {
    await tester.pumpWidget(_wrap(const WelcomeScreen(), FavouritesStore(
      storage: _FakeStorage(),
    )));

    expect(find.text('FoodMood'), findsOneWidget);
    expect(find.text('Find me something to cook'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
  });

  testWidgets('questionnaire advances only once an answer is chosen',
      (tester) async {
    await tester.pumpWidget(_wrap(
      const QuestionnaireScreen(),
      FavouritesStore(storage: _FakeStorage()),
    ));

    expect(find.text('Question 1 of 5'), findsOneWidget);

    // Next is disabled until something is selected.
    final next = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(next.onPressed, isNull);

    await tester.tap(find.text('Breakfast'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Question 2 of 5'), findsOneWidget);
  });

  testWidgets('results render a card per meal and a fallback notice',
      (tester) async {
    await tester.pumpWidget(_wrap(
      Scaffold(
        body: ResultsView(
          result: const SuggestionResult.fallback(
            kFallbackMeals,
            'Showing sample meals.',
          ),
          preferences: const UserPreferences(
            mealType: 'Dinner',
            diet: 'Vegan',
            mood: 'Comforting',
            spice: 'Mild',
            avoid: 'Nuts',
          ),
          onRegenerate: () {},
          onRestart: () {},
          onSearch: (_) {},
        ),
      ),
      FavouritesStore(storage: _FakeStorage()),
    ));

    expect(find.text('Dinner ideas'), findsOneWidget);
    expect(find.text('Showing sample meals.'), findsOneWidget);
    expect(find.text('Dinner · Vegan · Comforting · Mild · no Nuts'),
        findsOneWidget);
    for (final meal in kFallbackMeals) {
      expect(find.text(meal.name), findsOneWidget);
    }
  });

  testWidgets('saving a meal persists it and shows it on the saved screen',
      (tester) async {
    final storage = _FakeStorage();
    final store = FavouritesStore(storage: storage);

    await store.toggle(_meal);
    expect(store.contains(_meal), isTrue);
    expect(storage._entries, hasLength(1));

    await tester.pumpWidget(_wrap(const FavouritesScreen(), store));
    await tester.pumpAndSettle();

    expect(find.text('Miso noodle soup'), findsOneWidget);

    // A store built over the same storage restores what was written.
    final reloaded = FavouritesStore(storage: storage);
    await reloaded.load();
    expect(reloaded.meals.single.name, 'Miso noodle soup');
  });

  testWidgets('history survives a reload and is offered again',
      (tester) async {
    const preferences = UserPreferences(
      mealType: 'Dinner',
      diet: 'Vegan',
      mood: 'Comforting',
      spice: 'Mild',
      avoid: 'Nuts',
    );

    // A first run is recorded...
    final storage = _FakeHistoryStorage();
    await HistoryStore(storage: storage).add(
      SuggestionRun(
        createdAt: DateTime(2026, 8, 28, 12),
        preferences: preferences,
        meals: const [_meal],
        query: 'something with noodles',
      ),
    );

    // ...and a fresh store, as built on the next page load, restores it.
    final restored = HistoryStore(storage: storage);
    await restored.load();

    expect(restored.latest, isNotNull);
    expect(restored.latest!.meals.single.name, 'Miso noodle soup');
    expect(restored.latest!.query, 'something with noodles');
    expect(restored.latest!.label, '"something with noodles"');

    await tester.pumpWidget(_wrap(
      const WelcomeScreen(),
      FavouritesStore(storage: _FakeStorage()),
      history: restored,
    ));

    expect(find.text('Back to your last suggestions'), findsOneWidget);
  });

  testWidgets('history screen lists past runs newest first', (tester) async {
    const preferences = UserPreferences(
      mealType: 'Lunch',
      diet: 'Anything',
      mood: 'Fast and lazy',
      spice: 'Mild',
      avoid: 'Nothing',
    );

    final history = HistoryStore(storage: _FakeHistoryStorage());
    await history.add(SuggestionRun(
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      preferences: preferences,
      meals: const [_meal],
    ));
    await history.add(SuggestionRun(
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      preferences: preferences,
      meals: const [_meal],
      query: 'noodles',
    ));

    await tester.pumpWidget(_wrap(
      const HistoryScreen(),
      FavouritesStore(storage: _FakeStorage()),
      history: history,
    ));
    await tester.pump();

    expect(find.text('"noodles"'), findsOneWidget);
    expect(find.textContaining('2 hours ago'), findsOneWidget);
    expect(find.textContaining('2 days ago'), findsOneWidget);

    // Newest first.
    final tiles = tester.widgetList<Text>(find.byType(Text)).toList();
    final noodlesIndex = tiles.indexWhere((t) => t.data == '"noodles"');
    final summaryIndex =
        tiles.indexWhere((t) => t.data == preferences.summary);
    expect(noodlesIndex, lessThan(summaryIndex));
  });

  testWidgets('empty saved screen explains itself', (tester) async {
    await tester.pumpWidget(_wrap(
      const FavouritesScreen(),
      FavouritesStore(storage: _FakeStorage()),
    ));

    expect(find.text('Nothing saved yet'), findsOneWidget);
  });
}
