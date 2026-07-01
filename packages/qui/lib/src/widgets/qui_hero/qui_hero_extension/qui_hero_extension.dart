import 'package:flutter/widgets.dart';

/// Reusable behavior that can wrap a QUI hero variant.
///
/// Extensions are variant-agnostic: the same extension can be reused by box
/// heroes and future hero shapes. When multiple extensions are passed, they are
/// applied in declaration order, with the first extension becoming the outermost
/// wrapper.
///
/// ```dart
/// QuiHero.box(
///   tag: 'job-1-surface',
///   extensions: [
///     QuiHeroDragToCloseExtension(scrollController: scrollController),
///   ],
///   child: CustomScrollView(controller: scrollController),
/// )
/// ```
abstract class QuiHeroExtension {
  /// Creates a [QuiHeroExtension].
  const QuiHeroExtension();

  /// Wraps [child] with the behavior owned by this extension.
  Widget wrap({required BuildContext context, required Widget child});
}
