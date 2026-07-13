import 'package:flutter/material.dart';

import 'qui_theme_data.dart';

/// Convenience access to [QuiThemeData] from any [BuildContext].
///
/// ```dart
/// Container(
///   color: context.qui.colorScheme.background,
/// )
/// ```
extension QuiThemeContext on BuildContext {
  /// The [QuiThemeData] registered in the widget tree above this context.
  QuiThemeData get qui => Theme.of(this).extension<QuiThemeData>()!;
}
