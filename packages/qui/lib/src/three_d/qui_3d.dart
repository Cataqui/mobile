import 'package:flutter/material.dart';
import 'package:qui/gen/assets.gen.dart';

/// QUI-design-system accessor for bundled 3D image assets.
///
/// Provides a [build] method that renders a selected asset as an [Image] with
/// automatic downsampling for optimal memory use on low-end devices. The
/// default production instance is [Qui3d.instance]. Use a separate [Qui3d]
/// instance (e.g. in tests) for DI-friendly mocking.
///
/// ```dart
/// // Non-DI context:
/// Qui3d.instance.build(context, (assets) => assets.box, width: 200, height: 200);
///
/// // DI-provided (app-level, via Riverpod):
/// ref.watch(qui3dProvider).build(context, (assets) => assets.box, width: 300);
/// ```
class Qui3d {
  /// Creates a [Qui3d] instance.
  const Qui3d();

  /// Builds the asset selected by [selector] as an [Image] with downsampling.
  ///
  /// The [selector] receives the full set of generated 3D asset accessors
  /// so you can pick one via autocomplete.
  ///
  /// [context] is required to read the device pixel ratio for computing
  /// decode dimensions. [width] and [height] control both the display size
  /// and the decode cache size (width * dpr, height * dpr).
  Image build(
    BuildContext context,
    AssetGenImage Function($AssetsThreeDGen assets) selector, {
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
    Key? key,
  }) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    return selector(Assets.threeD).image(
      key: key,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      color: color,
      colorBlendMode: colorBlendMode,
      cacheWidth: width == null ? null : (width * dpr).ceil(),
      cacheHeight: height == null ? null : (height * dpr).ceil(),
    );
  }

  /// The default singleton [Qui3d] instance.
  ///
  /// Use in contexts where DI is not required.
  static const Qui3d instance = Qui3d();
}
