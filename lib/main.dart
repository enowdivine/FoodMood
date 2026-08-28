import 'package:flutter/material.dart';

import 'app.dart';
import 'services/favourites_store.dart';
import 'services/photo_service.dart';
import 'services/history_store.dart';
import 'services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Restore saved meals and the theme choice before the first frame, so nothing
  // pops in a moment after load.
  final favourites = FavouritesStore();
  final theme = ThemeController();
  final history = HistoryStore();
  await Future.wait([favourites.load(), theme.load(), history.load()]);

  runApp(
    FoodMoodApp(
      favourites: favourites,
      theme: theme,
      photos: PhotoService(),
      history: history,
    ),
  );
}
