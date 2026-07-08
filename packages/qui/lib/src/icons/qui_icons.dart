import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:qui/gen/assets.gen.dart';

/// QUI-design-system accessor for bundled SVG icons.
///
/// Provides a [build] method that renders a selected icon as an [SvgPicture].
/// The default production instance is [QuiIcons.instance]. Use a separate
/// [QuiIcons] instance (e.g. in tests) for DI-friendly mocking.
///
/// ```dart
/// // Non-DI context:
/// QuiIcons.instance.build((assets) => assets.cross, width: 16, height: 16);
///
/// // DI-provided (app-level, via Riverpod):
/// ref.watch(quiIconsProvider).build((assets) => assets.magnifierGlass, width: 20, height: 20);
/// ```
class QuiIcons {
  /// Creates a [QuiIcons] instance.
  const QuiIcons();

  /// Builds the icon selected by [selector] as an [SvgPicture].
  ///
  /// The [selector] receives the full set of generated icon accessors
  /// so you can pick one via autocomplete:
  ///
  /// ```dart
  /// QuiIcons.instance.build((assets) => assets.cross, width: 16, height: 16);
  /// ```
  SvgPicture build(
    SvgGenImage Function($AssetsIconsGen assets) selector, {
    double? width,
    double? height,
    ColorFilter? colorFilter,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool matchTextDirection = false,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
  }) {
    return selector(Assets.icons).svg(
      width: width,
      height: height,
      colorFilter: colorFilter,
      fit: fit,
      alignment: alignment,
      matchTextDirection: matchTextDirection,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
    );
  }

  /// The default singleton [QuiIcons] instance.
  ///
  /// Use in contexts where DI is not required.
  static const QuiIcons instance = QuiIcons();
}
