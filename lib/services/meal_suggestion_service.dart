import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../data/fallback_meals.dart';
import '../models/suggestion_result.dart';
import '../models/user_preferences.dart';
import 'meal_response_parser.dart';

/// Fetches meal suggestions from Groq's OpenAI-compatible chat completions API.
///
/// The public method never throws. Every failure mode — missing key, network
/// error, non-200, timeout, malformed body, unparseable array — resolves to the
/// fallback meals carrying a short, human-readable notice.
class MealSuggestionService {
  /// [client] is injectable so tests can supply a mock without touching the
  /// network; production callers use the default.
  MealSuggestionService({http.Client? client})
      : _client = client ?? http.Client();

  final http.Client _client;

  static const Duration _timeout = Duration(seconds: 30);

  /// One retry is enough for the failure this guards against — a rate limit or
  /// a brief upstream blip. More would just keep the user waiting.
  static const int _maxAttempts = 2;

  static const Duration _retryBackoff = Duration(milliseconds: 900);

  /// Rate limiting and upstream faults are worth retrying; a 401 or a 404 is
  /// a configuration error that will fail identically the second time.
  static bool _isTransient(int statusCode) =>
      statusCode == 408 || statusCode == 429 || statusCode >= 500;

  /// [request] is the user's own words, from the search box on the results
  /// screen. It steers the suggestions without loosening the diet or allergy
  /// constraints, which are never negotiable.
  /// [exclude] are dishes already suggested — asking again for the same ones
  /// is the main way a regenerate disappoints. [liked] are dishes the user has
  /// saved, used as a taste signal rather than a template.
  Future<SuggestionResult> fetch(
    UserPreferences preferences, {
    String? request,
    List<String> exclude = const [],
    List<String> liked = const [],
  }) async {
    if (!hasGroqKey) {
      return const SuggestionResult.fallback(
        kFallbackMeals,
        'Add your Groq API key in lib/config.dart to get live suggestions.',
      );
    }

    http.Response? response;

    for (var attempt = 1; attempt <= _maxAttempts; attempt++) {
      try {
        response = await _client
            .post(
              Uri.parse(kGroqEndpoint),
              headers: {
                'Authorization': 'Bearer $kGroqApiKey',
                'Content-Type': 'application/json',
              },
              body: jsonEncode(
              _requestBody(preferences, request, exclude, liked),
            ),
            )
            .timeout(_timeout);

        if (!_isTransient(response.statusCode)) break;
      } catch (_) {
        // Transport failure: worth one more go before giving up.
        response = null;
      }

      if (attempt < _maxAttempts) await Future<void>.delayed(_retryBackoff);
    }

    try {
      if (response == null) {
        return const SuggestionResult.fallback(
          kFallbackMeals,
          'Could not reach Groq. Showing sample meals.',
        );
      }

      if (response.statusCode != 200) {
        return SuggestionResult.fallback(
          kFallbackMeals,
          'Groq returned ${response.statusCode}. Showing sample meals.',
        );
      }

      final content = _extractContent(response.bodyBytes);
      if (content == null) {
        return const SuggestionResult.fallback(
          kFallbackMeals,
          'Unexpected response from Groq. Showing sample meals.',
        );
      }

      final meals = MealResponseParser.parse(content);
      if (meals.isEmpty) {
        return const SuggestionResult.fallback(
          kFallbackMeals,
          'Could not read the model output. Showing sample meals.',
        );
      }

      return SuggestionResult.live(meals);
    } catch (_) {
      // Deliberately broad: the UI contract is that this method always returns
      // something renderable, whatever the transport does.
      return const SuggestionResult.fallback(
        kFallbackMeals,
        'Could not reach Groq. Showing sample meals.',
      );
    }
  }

  Map<String, dynamic> _requestBody(
    UserPreferences preferences,
    String? request,
    List<String> exclude,
    List<String> liked,
  ) =>
      {
        'model': kGroqModel,
        'temperature': 0.9,
        'max_tokens': 2000,
        'messages': [
          {
            'role': 'system',
            'content': 'You are a practical home-cooking assistant. You treat '
                'stated allergies as absolute: never suggest a dish or an '
                'ingredient the user must avoid. Reply with a JSON array '
                'only. No prose, no markdown, no code fences.',
          },
          {
            'role': 'user',
            'content': _userPrompt(preferences, request, exclude, liked),
          },
        ],
      };

  String _userPrompt(
    UserPreferences p,
    String? request,
    List<String> exclude,
    List<String> liked,
  ) =>
      'Suggest exactly ${MealResponseParser.maxMeals} ${p.mealType} ideas for '
      'someone whose diet is "${p.diet}", whose mood is "${p.mood}", and who '
      'wants "${p.spice}" spice level.\n\n'
      'Every suggestion must be appropriate to eat as ${p.mealType}.\n\n'
      '${request != null && request.trim().isNotEmpty ? 'The user has asked '
          'specifically for: "${request.trim()}". Follow that closely — it '
          'matters more than the stated mood. The diet, spice level and any '
          'allergy constraints below still apply without exception.\n\n' : ''}'
      '${p.hasExclusion ? 'HARD CONSTRAINT: this person must avoid '
          '${p.avoid}. Every meal, and every ingredient you list, must be '
          'completely free of ${p.avoid} and anything derived from it. Do '
          'not suggest a dish that would normally contain it.\n\n' : ''}'
      'Return a JSON array of exactly ${MealResponseParser.maxMeals} objects, '
      'each with:\n'
      '"name" — short dish name,\n'
      '"why" — one or two sentences on why it fits this diet, mood and spice '
      'level,\n'
      '"cook_time" — e.g. "25 min",\n'
      '"servings" — e.g. "2",\n'
      '"difficulty" — Easy, Medium or Hard,\n'
      '"ingredients" — array of 5 to 8 short strings with quantities,\n'
      '"steps" — array of 3 to 6 short instruction strings.\n\n'
      '${exclude.isEmpty ? '' : 'Do not suggest any of these, they have '
          'already been shown: ${exclude.join('; ')}.\n\n'}'
      '${liked.isEmpty ? '' : 'This person has saved these before, so lean '
          'towards that kind of cooking without copying them: '
          '${liked.join('; ')}.\n\n'}'
      'Output the raw JSON array and nothing else.';

  /// Digs the assistant message out of the completions envelope.
  String? _extractContent(List<int> bodyBytes) {
    try {
      final body = jsonDecode(utf8.decode(bodyBytes));
      if (body is! Map<String, dynamic>) return null;

      final choices = body['choices'];
      if (choices is! List || choices.isEmpty) return null;

      final message = (choices.first as Map<String, dynamic>)['message'];
      if (message is! Map<String, dynamic>) return null;

      final content = message['content'];
      return content is String ? content : null;
    } catch (_) {
      return null;
    }
  }
}
