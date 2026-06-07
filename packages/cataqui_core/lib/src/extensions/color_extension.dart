import 'package:flutter/material.dart';

/// Shared helpers for Flutter [Color] values.
extension ColorExtension on Color {
  /// Returns this color darkened toward black by [amount].
  ///
  /// [amount] is clamped between `0` and `1`.
  Color darken(double amount) {
    return Color.lerp(this, Colors.black, amount.clamp(0, 1))!;
  }
}
