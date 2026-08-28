import 'package:flutter/widgets.dart';

import 'favourites_store.dart';

/// Provides the app's [FavouritesStore] to the widgets below it.
///
/// An [InheritedNotifier] means any widget calling [of] both reads the store
/// and rebuilds when it changes — no global, and no explicit listener wiring.
class FavouritesScope extends InheritedNotifier<FavouritesStore> {
  const FavouritesScope({
    required FavouritesStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static FavouritesStore of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<FavouritesScope>();
    assert(scope != null, 'No FavouritesScope found in the widget tree');
    return scope!.notifier!;
  }
}
