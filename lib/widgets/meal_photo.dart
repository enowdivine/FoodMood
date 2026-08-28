import 'package:flutter/material.dart';

import '../services/photo_scope.dart';
import 'meal_artwork.dart';

/// A photograph of a dish, looked up by name, with generated artwork standing
/// in while it loads and whenever the lookup or the image fails.
///
/// The lookup goes through [PhotoScope], whose service caches per session, so
/// a dish shown on a card and again on its detail page resolves to the same
/// photo without a second request.
class MealPhoto extends StatefulWidget {
  const MealPhoto({
    required this.name,
    this.width,
    this.height = 168,
    this.radius = 18,
    this.variant = 0,
    super.key,
  });

  final String name;
  final double? width;
  final double height;
  final double radius;

  /// Requests a different photo of the same dish, for multi-panel layouts.
  final int variant;

  @override
  State<MealPhoto> createState() => _MealPhotoState();
}

class _MealPhotoState extends State<MealPhoto> {
  Future<String?>? _photo;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _photo ??= PhotoScope.of(context)
        .photoFor(widget.name, variant: widget.variant);
  }

  @override
  Widget build(BuildContext context) {
    final placeholder = MealArtwork(
      name: widget.name,
      variant: widget.variant,
      width: widget.width ?? double.infinity,
      height: widget.height,
      radius: widget.radius,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: SizedBox(
        width: widget.width ?? double.infinity,
        height: widget.height,
        child: FutureBuilder<String?>(
          future: _photo,
          builder: (context, snapshot) {
            final url = snapshot.data;
            if (url == null) return placeholder;

            return Image.network(
              url,
              fit: BoxFit.cover,
              // Falls back to an <img> element where the canvas renderer would
              // otherwise be blocked; harmless elsewhere.
              webHtmlElementStrategy: WebHtmlElementStrategy.fallback,
              loadingBuilder: (context, child, progress) =>
                  progress == null ? child : placeholder,
              errorBuilder: (context, error, stack) => placeholder,
            );
          },
        ),
      ),
    );
  }
}
