import 'package:flutter/material.dart';
import 'package:qui/gen/assets.gen.dart';

/// Optimized asset-image decoding for [AssetGenImage].
///
/// Decodes the image at the physical pixel size needed for display
/// (`displaySize * devicePixelRatio`), capped via [ResizeImage]. This avoids
/// decoding large source rasters into memory at their native resolution — a
/// critical low-end-device (2–4 GB RAM) optimization.
///
/// The decode (cache) size is derived directly from the `width` and `height`
/// you pass — no separate "display override" params needed.
///
/// ```dart
/// // Decode at display resolution (150×150 logical → 150*dpr physical):
/// Qui3d.workItemsMess.downsampledImage(context, width: 150, height: 150);
///
/// // Height-only constraint, cacheHeight = 140 * devicePixelRatio:
/// Qui3d.locationPinRestingCracked.downsampledImage(context, height: 140);
/// ```
extension ImageExtension on AssetGenImage {
  Image downsampledImage(
    BuildContext context, {
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    FilterQuality filterQuality = FilterQuality.medium,
  }) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);

    return image(
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      filterQuality: filterQuality,
      cacheWidth: width == null ? null : (width * devicePixelRatio).ceil(),
      cacheHeight: height == null ? null : (height * devicePixelRatio).ceil(),
    );
  }
}
