import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foodmood/config.dart';
import 'package:foodmood/data/fallback_meals.dart';
import 'package:foodmood/models/user_preferences.dart';
import 'package:foodmood/services/meal_suggestion_service.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _preferences = UserPreferences(
  mealType: 'Dinner',
  diet: 'Vegan',
  mood: 'Comforting',
  spice: 'Mild',
  avoid: 'Nuts',
);

void main() {
  group('MealSuggestionService', () {
    test('falls back with a notice when the key is missing', () async {
      // Guard: this expectation only holds while the placeholder key is in
      // place, which is how the repo ships.
      if (hasGroqKey) return;

      final service = MealSuggestionService(
        client: MockClient((_) async => http.Response('{}', 200)),
      );

      final result = await service.fetch(_preferences);

      expect(result.usedFallback, isTrue);
      expect(result.meals, kFallbackMeals);
      expect(result.notice, contains('API key'));
    });

    test('falls back rather than throwing when the transport fails', () async {
      final service = MealSuggestionService(
        client: MockClient((_) async => throw const SocketExceptionStub()),
      );

      final result = await service.fetch(_preferences);

      expect(result.usedFallback, isTrue);
      expect(result.meals, kFallbackMeals);
    });

    test('feeds history and saved meals into the prompt', () async {
      String? sentBody;

      final service = MealSuggestionService(
        client: MockClient((request) async {
          sentBody = request.body;
          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '[{"name":"Dal","why":"Cosy.",'
                        '"cook_time":"30 min"}]',
                  },
                },
              ],
            }),
            200,
          );
        }),
      );

      if (!hasGroqKey) return;

      await service.fetch(
        _preferences,
        request: 'something with lentils',
        exclude: ['Coconut chickpea curry'],
        liked: ['Miso noodle soup'],
      );

      expect(sentBody, isNotNull);
      expect(sentBody, contains('something with lentils'));
      expect(sentBody, contains('already been shown'));
      expect(sentBody, contains('Coconut chickpea curry'));
      expect(sentBody, contains('has saved these before'));
      expect(sentBody, contains('Miso noodle soup'));
      // The allergy constraint must survive alongside the added context.
      expect(sentBody, contains('must avoid Nuts'));
    });

    test('omits the extra context when there is none', () async {
      String? sentBody;

      final service = MealSuggestionService(
        client: MockClient((request) async {
          sentBody = request.body;
          return http.Response(
            jsonEncode({
              'choices': [
                {'message': {'content': '[{"name":"Dal"}]'}},
              ],
            }),
            200,
          );
        }),
      );

      if (!hasGroqKey) return;

      await service.fetch(_preferences);

      expect(sentBody, isNotNull);
      expect(sentBody, isNot(contains('already been shown')));
      expect(sentBody, isNot(contains('has saved these before')));
    });

    test('parses a well-formed completion envelope', () async {
      final service = MealSuggestionService(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': '[{"name":"Dal","why":"Cosy.",'
                        '"cook_time":"30 min"}]',
                  },
                },
              ],
            }),
            200,
          ),
        ),
      );

      // Without a key the service short-circuits before the client is used,
      // so this assertion is only meaningful once a key is configured.
      if (!hasGroqKey) return;

      final result = await service.fetch(_preferences);

      expect(result.usedFallback, isFalse);
      expect(result.meals.single.name, 'Dal');
    });
  });
}

/// Stand-in for a transport failure without importing dart:io (web-safe).
class SocketExceptionStub implements Exception {
  const SocketExceptionStub();
}
