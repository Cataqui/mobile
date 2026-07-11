import 'package:flutter/material.dart';

import '../oklch.dart';

/// Extension on [Oklch] to convert back to sRGB [Color].
extension OklchExtension on Oklch {
  /// Returns the sRGB [Color] representation of this OKLCH color.
  Color toColor() => Oklch.toColor(l, c, h);
}
