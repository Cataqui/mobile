import 'package:qui/gen/assets.gen.dart';

/// QUI-design-system accessor for bundled Lottie animations.
///
/// Provides a [lotties] getter for the generated asset accessors and an
/// [animate] flag that controls whether the animation plays.  The default
/// production instance is [QuiLottie.shared] (a lazy singleton).  Use a
/// separate [QuiLottie] instance (e.g., `QuiLottie(animate: false)`) in tests
/// to prevent infinite-loop Lottie tickers from blocking `pumpAndSettle`.
///
/// ```dart
/// // Production (non-DI context):
/// QuiLottie.shared.lotties.loadingSlime.lottie(width: 80, height: 80);
///
/// // DI-provided (app-level, via Riverpod):
/// ref.watch(quiLottieProvider).lotties.loadingSlime.lottie(animate: quiLottie.animate, width: 150, height: 150);
/// ```
class QuiLottie {
  /// Creates a [QuiLottie] instance with the given [animate] flag.
  ///
  /// When [animate] is `false`, the Lottie widget renders its first frame
  /// statically (no animation ticker is started).  This is used in tests.
  QuiLottie({this.animate = true});

  /// Whether the Lottie animation should play when rendered.
  final bool animate;

  /// The generated Lottie asset accessors (e.g., `.loadingSlime`).
  $AssetsLottieGen get lotties => Assets.lottie;

  /// The default lazy singleton [QuiLottie] instance (animate: `true`).
  ///
  /// Use this in contexts where Riverpod DI is not available (e.g., widgets
  /// inside the `qui` package itself).
  static final QuiLottie shared = QuiLottie();
}
