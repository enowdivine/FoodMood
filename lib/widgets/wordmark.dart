import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The app's logotype: a gradient-filled wordmark beside the mark.
///
/// The gradient is painted with a [ShaderMask] rather than an image so it
/// stays crisp at any size and inherits the theme's own colours.
class Wordmark extends StatelessWidget {
  const Wordmark({super.key, this.size = WordmarkSize.regular});

  final WordmarkSize size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isLarge = size == WordmarkSize.large;

    final gradient = LinearGradient(
      colors: [scheme.primary, AppTheme.seedDeep, scheme.tertiary],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    final textStyle = (isLarge
            ? theme.textTheme.headlineMedium
            : theme.textTheme.titleLarge)
        ?.copyWith(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.8,
      height: 1.1,
      // The shader supplies the colour; this just has to be opaque.
      color: Colors.white,
    );

    final box = isLarge ? 52.0 : 40.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: box,
          height: box,
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(isLarge ? 16 : 12),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Icon(
            Icons.restaurant_menu,
            size: isLarge ? 27 : 22,
            color: Colors.white,
          ),
        ),
        SizedBox(width: isLarge ? 14 : AppTheme.gapSm),
        ShaderMask(
          shaderCallback: (bounds) => gradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text('FoodMood', style: textStyle),
        ),
      ],
    );
  }
}

enum WordmarkSize { regular, large }
