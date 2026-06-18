import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:qui/gen/fonts.gen.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

/// A QUI loading indicator with shimmering text.
///
/// Displays a [CircularProgressIndicator] alongside a text label with a
/// shimmer sweep animation. Designed for loading states and in-progress
/// affordances.
///
/// ```dart
/// QuiLoadingText(
///   text: 'Carregando oportunidades...',
/// )
/// ```
class QuiLoadingText extends StatelessWidget {
  /// Creates a QUI loading indicator.
  const QuiLoadingText({required this.text, super.key, this.progressIndicatorColor});

  /// The text label shown next to the progress indicator.
  final String text;

  /// Color of the [CircularProgressIndicator].
  ///
  /// Defaults to `context.qui.colors.primary`.
  final Color? progressIndicatorColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final indicatorColor = progressIndicatorColor ?? colors.primary;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildIndicator(context, indicatorColor, disableAnimations),
        const SizedBox(width: 12),
        _buildText(context, disableAnimations),
      ],
    );
  }

  Widget _buildText(BuildContext context, bool disableAnimations) {
    final colors = context.qui.colors;
    final textWidget = Text(
      text,
      style: TextStyle(fontFamily: FontFamily.inter, fontSize: 16.5, fontWeight: FontWeight.w500, color: colors.shimmerTextBase),
    );

    if (disableAnimations) return textWidget;

    return textWidget
        .animate(onPlay: (controller) => controller.repeat())
        .shimmer(duration: const Duration(milliseconds: 1500), color: colors.shimmerTextGlow, padding: 0);
  }

  Widget _buildIndicator(BuildContext context, Color color, bool disableAnimations) {
    return SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2, color: color));
  }
}

/// Preview of the [QuiLoadingText] widget.
@Preview(name: 'QuiLoadingText', group: 'Feedback')
Widget quiLoadingTextPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            QuiLoadingText(text: 'Carregando oportunidades...'),
            SizedBox(height: 20),
            QuiLoadingText(text: 'Buscando...', progressIndicatorColor: Color(0xFF00A676)),
          ],
        ),
      ),
    ),
  );
}
