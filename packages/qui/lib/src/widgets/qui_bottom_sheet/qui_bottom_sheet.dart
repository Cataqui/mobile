import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_drag_resistance/qui_drag_resistance.dart';

part '_qui_bottom_sheet_drag_surface.dart';
part '_qui_bottom_sheet_handle.dart';
part '_qui_bottom_sheet_handle_delegate.dart';
part '_qui_bottom_sheet_route.dart';
part '_qui_bottom_sheet_scrim_drag_surface.dart';
part '_qui_bottom_sheet_surface.dart';
part '_qui_bottom_sheet_transition.dart';
part '_qui_bottom_sheet_transition_render_object.dart';

/// A modal QUI surface for compact information and focused actions.
///
/// Use [show] to present [Widget] content near the physical bottom edge of the
/// current navigator.
///
/// Set `scrollable: true` when QUI should own scrolling for content that is
/// taller than the sheet. An upward scroll first expands it to 85 percent of that
/// viewport; after it reaches that height, the same gesture scrolls the content.
///
/// The sheet can be dismissed with a downward drag when its content is not
/// scrollable or is already at the top. Back navigation, accessibility dismiss
/// actions, taps on the modal backdrop, and downward backdrop swipes also
/// dismiss it.
///
/// ```dart
/// QuiBottomSheet.show(
///   context,
///   child: const Text('Opportunity details'),
/// );
/// ```
///
/// ```dart
/// QuiBottomSheet.show(
///   context,
///   scrollable: true,
///   child: Column(
///     children: const [
///       Text('Opportunity details'),
///       SizedBox(height: 16),
///       Text('Requirements'),
///     ],
///   ),
/// );
/// ```
///
abstract final class QuiBottomSheet {
  /// Shows a QUI bottom sheet above the nearest navigator.
  ///
  /// The [child] is placed inside fixed QUI content padding and an internal
  /// safe area. When [scrollable] is `false`, small children keep their
  /// intrinsic height while tall children receive a maximum height equal to 85
  /// percent of the keyboard-adjusted viewport.
  ///
  /// When [scrollable] is `true`, the sheet starts at one third of the
  /// keyboard-adjusted viewport and QUI wraps [child] in a scroll view. Upward
  /// scrolling expands the sheet before scrolling its content. The [child]
  /// must not contain another vertical scrollable in this mode. Keep the child
  /// to a bounded amount of content because it is built as one scrollable box;
  /// do not use this mode for an unbounded or very large collection.
  ///
  /// Returns the value supplied to `Navigator.pop` when the sheet closes, or
  /// `null` when it is dismissed without a result.
  static Future<T?> show<T>(BuildContext context, {required Widget child, bool scrollable = false}) {
    final navigator = Navigator.of(context);
    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final colorScheme = context.qui.colorScheme;

    return navigator.push<T>(
      _QuiBottomSheetRoute<T>(
        child: child,
        capturedThemes: InheritedTheme.capture(from: context, to: navigator.context),
        barrierColor: colorScheme.overlay.scrim,
        barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
        disableAnimations: disableAnimations,
        scrollable: scrollable,
      ),
    );
  }
}
