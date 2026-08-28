import 'package:flutter/widgets.dart';

import 'history_store.dart';

/// Provides the app's [HistoryStore] to the widgets below it.
class HistoryScope extends InheritedNotifier<HistoryStore> {
  const HistoryScope({
    required HistoryStore store,
    required super.child,
    super.key,
  }) : super(notifier: store);

  static HistoryStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HistoryScope>();
    assert(scope != null, 'No HistoryScope found in the widget tree');
    return scope!.notifier!;
  }
}
