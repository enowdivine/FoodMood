import 'package:flutter_test/flutter_test.dart';
import 'package:foodmood/services/meal_response_parser.dart';

void main() {
  group('MealResponseParser', () {
    test('parses a bare JSON array', () {
      final meals = MealResponseParser.parse('''
[{"name":"Shakshuka","why":"Warm and quick.","cook_time":"20 min"}]
''');

      expect(meals, hasLength(1));
      expect(meals.first.name, 'Shakshuka');
      expect(meals.first.cookTime, '20 min');
    });

    test('strips markdown code fences', () {
      final meals = MealResponseParser.parse('''
```json
[{"name":"Ramen","why":"Comfort in a bowl.","cook_time":"30 min"}]
```
''');

      expect(meals.single.name, 'Ramen');
    });

    test('recovers an array wrapped in prose', () {
      final meals = MealResponseParser.parse(
        'Sure! Here are your meals: '
        '[{"name":"Tacos","why":"Fast.","cook_time":"15 min"}] Enjoy!',
      );

      expect(meals.single.name, 'Tacos');
    });

    test('accepts camelCase and alternate key spellings', () {
      final meals = MealResponseParser.parse(
        '[{"meal":"Pho","reason":"Light.","cookTime":"40 min"}]',
      );

      expect(meals.single.name, 'Pho');
      expect(meals.single.why, 'Light.');
      expect(meals.single.cookTime, '40 min');
    });

    test('unwraps an object that nests the array', () {
      final meals = MealResponseParser.parse(
        '{"meals":[{"name":"Chilli","why":"Hot.","cook_time":"45 min"}]}',
      );

      expect(meals.single.name, 'Chilli');
    });

    test('caps the list at the render limit', () {
      final meals = MealResponseParser.parse(
        '[{"name":"A"},{"name":"B"},{"name":"C"},{"name":"D"},'
        '{"name":"E"},{"name":"F"},{"name":"G"}]',
      );

      expect(meals, hasLength(MealResponseParser.maxMeals));
    });

    test('drops entries with no name', () {
      final meals = MealResponseParser.parse('[{"why":"No name here."}]');

      expect(meals, isEmpty);
    });

    test('returns empty on malformed JSON instead of throwing', () {
      expect(MealResponseParser.parse('not json at all'), isEmpty);
      expect(MealResponseParser.parse('[{"name":'), isEmpty);
      expect(MealResponseParser.parse(''), isEmpty);
    });
  });
}
