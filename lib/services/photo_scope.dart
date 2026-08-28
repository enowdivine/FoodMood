import 'package:flutter/widgets.dart';

import 'photo_service.dart';

/// Provides the shared [PhotoService] — and with it the session's photo cache —
/// to every widget that renders a dish.
class PhotoScope extends InheritedWidget {
  const PhotoScope({
    required this.service,
    required super.child,
    super.key,
  });

  final PhotoService service;

  static PhotoService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<PhotoScope>();
    assert(scope != null, 'No PhotoScope found in the widget tree');
    return scope!.service;
  }

  @override
  bool updateShouldNotify(PhotoScope oldWidget) => service != oldWidget.service;
}
