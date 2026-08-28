import 'dart:convert';

import 'package:http/http.dart' as http;

/// Finds a photograph for a dish by name.
///
/// Openverse indexes Creative Commons images and, unlike a keyword stock feed,
/// actually matches titles — "Creamy tomato basil soup" returns a photo of that
/// soup rather than a tomato. It needs no API key and serves CORS headers, so
/// it works from a web build.
///
/// Results are cached for the session: the same dish is asked for on its card,
/// then again on its detail page, and re-querying would be wasteful and would
/// make the photo change under the user.
class PhotoService {
  PhotoService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _endpoint = 'https://api.openverse.org/v1/images/';

  static const Duration _timeout = Duration(seconds: 8);

  /// How many results to request; a small pool lets the detail screen show
  /// several different photos of one dish.
  static const int _poolSize = 6;

  final Map<String, List<String>> _cache = {};

  /// Returns a photo URL for [dishName], or null if nothing usable is found.
  ///
  /// [variant] picks a different photo of the same dish for multi-panel
  /// layouts. Never throws — a null result means the caller draws its
  /// placeholder.
  Future<String?> photoFor(String dishName, {int variant = 0}) async {
    final query = _queryFor(dishName);
    if (query.isEmpty) return null;

    final cached = _cache[query];
    if (cached != null) return _pick(cached, variant);

    try {
      final uri = Uri.parse(_endpoint).replace(queryParameters: {
        'q': query,
        'page_size': '$_poolSize',
        // Photographs only, and nothing flagged as sensitive.
        'category': 'photograph',
        'mature': 'false',
      });

      final response = await _client.get(uri).timeout(_timeout);
      if (response.statusCode != 200) {
        _cache[query] = const [];
        return null;
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is! Map<String, dynamic>) return null;

      final results = body['results'];
      if (results is! List) return null;

      final urls = results
          .whereType<Map<String, dynamic>>()
          .map((result) => result['url'])
          .whereType<String>()
          .where((url) => url.startsWith('https://'))
          .toList(growable: false);

      _cache[query] = urls;
      return _pick(urls, variant);
    } catch (_) {
      // Cache the miss so a dead network does not retry on every rebuild.
      _cache[query] = const [];
      return null;
    }
  }

  String? _pick(List<String> urls, int variant) =>
      urls.isEmpty ? null : urls[variant % urls.length];

  /// Words that would pull the search away from the dish itself.
  static const Set<String> _stopWords = {
    'and', 'with', 'the', 'a', 'of', 'in', 'on', 'one', 'pan', 'quick',
    'easy', 'simple', 'homemade', 'style', 'fresh', 'best', 'my', 'mild',
    'hot', 'spicy', 'vegan', 'vegetarian', 'served',
  };

  /// Keeps the dish name, minus filler, as the search phrase.
  static String _queryFor(String dishName) => dishName
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z\s]'), ' ')
      .split(RegExp(r'\s+'))
      .where((word) => word.length > 2 && !_stopWords.contains(word))
      .take(4)
      .join(' ');
}
