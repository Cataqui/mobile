import 'package:flutter/material.dart';
import 'package:qui/gen/lotties.g.dart';
import 'package:qui/qui.dart';

/// A QUI animated hint showing a hand swiping upward on a phone screen.
///
/// Renders a looping animation: a neutral phone body, a hand
/// pointer that swipes up the phone's face, an up-arrow that slides upward,
/// and a touch ripple that expands from the contact point.
///
///
///
/// ```dart
/// QuiSwipeUpHint()
/// QuiSwipeUpHint(size: 200)
/// QuiSwipeUpHint(
///   size: 200,
///   phoneColor: Color(0xFF1F1F1F),
///   handColor: Color(0xFFFF4A4B),
/// )
/// ```
///
class QuiSwipeUpHint extends StatelessWidget {
  /// Creates a QUI swipe-up hint.
  const QuiSwipeUpHint({super.key, this.height = 120.0, this.phoneColor, this.accentColor});

  /// Height of the widget in logical pixels.
  final double height;

  /// Override color for the phone body.
  ///
  /// When `null`, defaults to [QuiColorScheme.colors.neutral.solid] from the
  /// active [QuiTheme].
  final Color? phoneColor;

  /// Override color for the hand, arrow, and ripple (the accent elements).
  ///
  /// When `null`, defaults to [QuiColorScheme.colors.neutral.subtle] from the
  /// active [QuiTheme].
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colorScheme.colors.neutral;
    final phone = phoneColor ?? colors.solid;
    final hand = accentColor ?? colors.subtle;

    return $Lotties.swipeUpPhoneAnimation(
      height: height,
      color1: hand,
      color2: phone,
      progress: MediaQuery.disableAnimationsOf(context) ? 0.3 : null,
    );
  }
}
