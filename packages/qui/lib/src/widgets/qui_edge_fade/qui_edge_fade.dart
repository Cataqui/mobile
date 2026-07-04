import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_edge_fade_enums.dart';

/// A QUI edge-fade gradient that fades content at a screen edge.
///
/// Renders a vertical [LinearGradient] that fades from an opaque [color] at
/// the chosen [position] to fully transparent, wrapped in an
/// [IgnorePointer] and [RepaintBoundary] so it never intercepts hit-testing
/// and never triggers repaints of the content beneath it.
///
/// ## Usage
///
/// The widget is **not** self-positioning. Place it inside a [Stack] using a
/// [Positioned] at the matching screen edge. The [position] prop only
/// controls which end of the gradient is opaque.
///
/// ```dart
/// Stack(
///   children: [
///     const Positioned.fill(child: MyFeed()),
///     Positioned(
///       top: 0, left: 0, right: 0,
///       child: QuiEdgeFade(position: QuiEdgeFadePosition.top),
///     ),
///     Positioned(
///       bottom: 0, left: 0, right: 0,
///       child: QuiEdgeFade(position: QuiEdgeFadePosition.bottom),
///     ),
///   ],
/// )
/// ```
///
/// See also:
///  * [QuiEdgeFadePosition], the screen edges supported by this widget.
class QuiEdgeFade extends StatelessWidget {
  /// Creates a QUI edge-fade gradient.
  const QuiEdgeFade({required this.position, this.color, super.key});

  /// Which screen edge the gradient fades from.
  ///
  /// Drives the gradient's opaque-to-transparent direction. The consumer must
  /// place the widget at the matching edge via [Positioned].
  final QuiEdgeFadePosition position;

  /// Solid color the gradient fades from.
  ///
  /// When `null`, resolves to `context.qui.colors.background` at build time.
  final Color? color;

  /// Fraction of the device viewport height used for the fade height.
  static const double _heightFactor = 1 / 7;

  /// Lower bound for the resolved fade height, in logical pixels.
  static const double _minHeight = 72;

  /// Upper bound for the resolved fade height, in logical pixels.
  static const double _maxHeight = 120;

  static double _resolveHeight(BuildContext context) {
    final deviceHeight = MediaQuery.sizeOf(context).height;
    final scaled = deviceHeight * _heightFactor;
    return scaled.clamp(_minHeight, _maxHeight);
  }

  static (Alignment, Alignment) _resolveGradientAlignment(QuiEdgeFadePosition position) {
    return switch (position) {
      QuiEdgeFadePosition.top => (Alignment.topCenter, Alignment.bottomCenter),
      QuiEdgeFadePosition.bottom => (Alignment.bottomCenter, Alignment.topCenter),
    };
  }

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? context.qui.colors.background;
    final height = _resolveHeight(context);
    final (begin, end) = _resolveGradientAlignment(position);

    return SizedBox(
      height: height,
      child: IgnorePointer(
        child: RepaintBoundary(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: begin,
                end: end,
                stops: const [0.0, 0.3, 1.0],
                colors: [resolvedColor, resolvedColor, resolvedColor.withValues(alpha: 0)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Preview of the [QuiEdgeFade] widget.
@Preview(name: 'QuiEdgeFade', group: 'Overlay')
Widget quiEdgeFadePreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: const Scaffold(
      backgroundColor: Color(0xFFE8E8E8),
      body: Stack(
        children: [
          Center(child: Text('Content under the fades')),
          Positioned(top: 0, left: 0, right: 0, child: QuiEdgeFade(position: QuiEdgeFadePosition.top)),
          Positioned(bottom: 0, left: 0, right: 0, child: QuiEdgeFade(position: QuiEdgeFadePosition.bottom)),
        ],
      ),
    ),
  );
}
