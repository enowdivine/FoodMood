import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/favourites_scope.dart';
import 'services/favourites_store.dart';
import 'services/photo_scope.dart';
import 'services/photo_service.dart';
import 'services/history_scope.dart';
import 'services/history_store.dart';
import 'services/theme_controller.dart';
import 'services/theme_scope.dart';
import 'theme/app_theme.dart';

/// Removes the scrollbar Flutter web paints over scrollable areas, so the
/// single-column layout reads as an app rather than a web page. Scrolling
/// itself — wheel, trackpad, touch — is untouched.
class _NoScrollbarBehavior extends MaterialScrollBehavior {
  const _NoScrollbarBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) =>
      child;
}

/// Installs the app's shared dependencies above [MaterialApp], so every screen
/// resolves them from context and tests can supply their own.
class FoodMoodApp extends StatelessWidget {
  const FoodMoodApp({
    required this.favourites,
    required this.theme,
    required this.photos,
    required this.history,
    super.key,
  });

  final FavouritesStore favourites;
  final ThemeController theme;

  /// One instance for the app, so the photo cache is shared across screens.
  final PhotoService photos;

  /// Past suggestion runs, restored from storage at startup.
  final HistoryStore history;

  @override
  Widget build(BuildContext context) {
    return PhotoScope(
      service: photos,
      child: HistoryScope(
        store: history,
        child: FavouritesScope(
          store: favourites,
          child: ThemeScope(
            controller: theme,
            // Rebuilds MaterialApp when the mode changes; the scopes above it
            // stay put, so no screen state is lost on a toggle.
            child: ListenableBuilder(
              listenable: theme,
              builder: (context, _) => MaterialApp(
                title: 'FoodMood',
                debugShowCheckedModeBanner: false,
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: theme.mode,
                scrollBehavior: const _NoScrollbarBehavior(),
                home: const WelcomeScreen(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
