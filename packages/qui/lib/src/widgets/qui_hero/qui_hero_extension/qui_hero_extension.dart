import 'package:flutter/widgets.dart';

import '../heroes/background/qui_hero_background.dart';
import '../qui_hero.dart';
import '../qui_hero_page/qui_hero_page_route.dart';

/// The base class for composable behaviors attached to a [QuiHero] variant.
///
/// Extensions are variant-agnostic — a single extension works with box heroes,
/// text heroes, and future hero shapes without modification. Each extension
/// wraps the hero subtree and may inject gesture detection, layout adjustments,
/// or visual effects.
///
/// ## Composition order
///
/// When a hero receives multiple extensions via
/// [QuiHeroBackground] with `extensions: [...]`, they are applied in declaration
/// order: the **first** extension in the list becomes the **outermost** wrapper.
///
/// ```dart
/// // Declaration order
/// extensions: [A, B, C]
///
/// // Resulting widget tree
/// A(context,
///   child: B(context,
///     child: C(context,
///       child: heroContent,
///     ),
///   ),
/// )
/// ```
///
/// ## Implementing a custom extension
///
/// Subclass [QuiHeroExtension] and override [wrap]. The `context` parameter
/// gives access to the [QuiHeroPageRoute] (via [QuiHeroPageRoute.maybeOf]) for
/// extensions that need to drive interactive pop or read route state.
///
/// ```dart
/// class QuiHeroPaddingExtension extends QuiHeroExtension {
///   const QuiHeroPaddingExtension({required this.padding});
///
///   final EdgeInsets padding;
///
///   @override
///   Widget wrap({required BuildContext context, required Widget child}) {
///     return Padding(padding: padding, child: child);
///   }
/// }
/// ```
///
/// See also:
///  * [QuiHero], the hero widget that accepts extensions.
abstract class QuiHeroExtension {
  /// Creates a [QuiHeroExtension].
  const QuiHeroExtension();

  /// Wraps [child] with the behavior owned by this extension.
  ///
  /// The [context] is the [BuildContext] at the point where the hero renders.
  /// Use it to access inherited widgets, the [Navigator], or — commonly — the
  /// [QuiHeroPageRoute] via [QuiHeroPageRoute.maybeOf] to drive interactive
  /// pop gestures.
  ///
  /// The returned widget replaces [child] in the hero's render tree. To
  /// preserve the hero's layout and semantics, the returned widget should
  /// typically include [child] as a descendant.
  Widget wrap({required BuildContext context, required Widget child});
}
