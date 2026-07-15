part of 'qui_tap.dart';

/// Tap feedback animation variants supported by [QuiTap].
enum QuiTapAnimationType {
  /// No visual feedback on press; fires [QuiTap.onPressed] immediately.
  none,

  /// Scales down while pressed.
  scale,

  /// Scales down and fades while pressed.
  scaleFade,
}
