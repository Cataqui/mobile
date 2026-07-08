import 'package:flutter/widgets.dart';
import 'package:lottie/lottie.dart';
import 'package:qui/gen/assets.gen.dart';

/// QUI-design-system accessor for bundled Lottie animations.
///
/// Provides a [build] method that renders a selected animation as a
/// [LottieBuilder]. The [animate] flag controls whether the animation plays
/// (default `true`). The default production instance is [QuiLottie.instance].
/// Use a separate [QuiLottie] instance (e.g., `QuiLottie(animate: false)`) in
/// tests to prevent infinite-loop Lottie tickers from blocking `pumpAndSettle`.
///
/// ```dart
/// // Non-DI context:
/// QuiLottie.instance.build((assets) => assets.loadingSlime, width: 80, height: 80);
///
/// // DI-provided (app-level, via Riverpod):
/// ref.watch(quiLottieProvider).build((assets) => assets.loadingSlime, width: 150, height: 150);
/// ```
class QuiLottie {
  /// Creates a [QuiLottie] instance with the given [animate] flag.
  ///
  /// When [animate] is `false`, the Lottie widget renders its first frame
  /// statically (no animation ticker is started). This is used in tests.
  const QuiLottie({this.animate = true});

  /// Whether the Lottie animation should play when rendered.
  final bool animate;

  /// Builds the animation selected by [selector] as a [LottieBuilder].
  ///
  /// The [selector] receives the full set of generated Lottie accessors
  /// so you can pick one via autocomplete.
  LottieBuilder build(
    LottieGenImage Function($AssetsLottieGen assets) selector, {
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry? alignment,
    bool? repeat,
    bool? reverse,
  }) {
    return selector(Assets.lottie).lottie(
      animate: animate,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      reverse: reverse,
    );
  }

  /// The default singleton [QuiLottie] instance.
  ///
  /// Use in contexts where DI is not required.
  static const QuiLottie instance = QuiLottie();
}
