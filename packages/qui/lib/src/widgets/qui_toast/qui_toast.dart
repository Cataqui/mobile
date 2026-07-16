import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/qui.dart';

part '_qui_toast_overlay.dart';
part '_qui_toast_presentation.dart';
part 'qui_toast_enums.dart';
part 'qui_toast_gesture_transform/_qui_toast_gesture_transform_render_object.dart';
part 'qui_toast_gesture_transform/_qui_toast_gesture_transform_widget.dart';
part 'qui_toast_messenger.dart';
part 'qui_toast_slide/_qui_toast_slide_render_object.dart';
part 'qui_toast_slide/_qui_toast_slide_widget.dart';

/// A toast surface for transient messages.
///
/// `QuiToast` renders a compact floating toast. Use [show]
/// for normal app feedback so the toast is inserted above the provided
/// [BuildContext].
///
/// Calling [show] while a toast is already visible replaces the previous toast
/// instead of stacking messages. `QuiApp.router` auto-injects a
/// [QuiToastMessenger] that keeps toast entries above hero flights.
///
/// ```dart
/// QuiToast.show(
///   context,
///   message: 'Something went wrong',
/// );
/// ```
///
/// See also:
///  * [QuiToastType], the status type that controls the toast colors and icon.
///  * [QuiToastMessenger], the messenger that keeps toast entries above the
///    navigator.
class QuiToast extends StatelessWidget {
  /// Creates a QUI toast widget.
  ///
  /// Use the constructor for direct rendering in previews, tests, or composed
  /// surfaces. Use [show] for the common overlay behavior.
  const QuiToast({required this.message, super.key, this.type = QuiToastType.error});

  /// The visible message presented in the toast.
  final String message;

  /// The status type that controls colors and iconography.
  final QuiToastType type;

  /// Shows a QUI toast above [context].
  ///
  /// The [message] is displayed after the safe area. The [type] resolves
  /// the icon color. The optional [duration] controls how long the toast
  /// remains visible before dismissing; when omitted, it estimates a reading
  /// duration from [message]. The [padding] is applied after the safe area
  /// and controls the toast inset from the overlay edges.
  ///
  /// When a [QuiToastMessenger] ancestor is found via [context], the toast is
  /// inserted into that messenger's overlay so it remains above route and hero
  /// overlays. Otherwise, the furthest overlay above [context] is used as a
  /// fallback.
  ///
  /// If another toast is visible, it is removed before the new toast is shown.
  /// If [context] has no overlay, this method safely does nothing.
  static void show(
    BuildContext context, {
    required String message,
    QuiToastType type = QuiToastType.error,
    Duration? duration,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
  }) {
    final messenger = QuiToastMessenger.maybeOf(context);
    final overlay = messenger?.overlay ?? Overlay.maybeOf(context, rootOverlay: true);

    if (overlay == null) return;

    final disableAnimations = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final capturedThemes = InheritedTheme.capture(from: context, to: overlay.context);

    messenger?.dismissActive();

    late final _QuiToastPresentation presentation;

    final entry = OverlayEntry(
      builder: (context) => capturedThemes.wrap(
        _QuiToastOverlay(
          message: message,
          type: type,
          duration: duration ?? _estimateDuration(message),
          disableAnimations: disableAnimations,
          padding: padding,
          onDismissed: () {
            presentation.remove();

            if (identical(messenger?._activePresentation, presentation)) {
              messenger?._activePresentation = null;
            }
          },
        ),
      ),
    );

    presentation = _QuiToastPresentation(entry: entry);
    messenger?._activePresentation = presentation;

    overlay.insert(entry);
  }

  static const double _iconSize = 30;
  static const double _iconTextGap = 12;
  static const double _contentPaddingLeft = 14;
  static const double _contentPaddingRight = 26;
  static const int _maxLines = 2;

  static const Duration _minAutoDuration = Duration(milliseconds: 2500);
  static const Duration _maxAutoDuration = Duration(milliseconds: 8000);
  static const Duration _appearDuration = Duration(milliseconds: 280);
  static const Duration _dismissDuration = Duration(milliseconds: 220);
  static const double _readableCharactersPerSecond = 14;

  static Duration _estimateDuration(String message) {
    final readableCharacters = message.trim().isEmpty ? 1 : message.trim().length;
    final milliseconds = (readableCharacters / _readableCharactersPerSecond * 1000).round();
    final duration = Duration(milliseconds: milliseconds);

    if (duration < _minAutoDuration) return _minAutoDuration;
    if (duration > _maxAutoDuration) return _maxAutoDuration;

    return duration;
  }

  bool _isUsingTwoLines(BuildContext context, BoxConstraints constraints, TextStyle textStyle) {
    if (!constraints.hasBoundedWidth) return false;

    final maxTextWidth = constraints.maxWidth - _iconSize - _iconTextGap - _contentPaddingLeft - _contentPaddingRight;
    if (maxTextWidth <= 0) return true;

    final textPainter = TextPainter(
      maxLines: _maxLines,
      text: TextSpan(text: message, style: textStyle),
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
    )..layout(maxWidth: maxTextWidth);

    final usesTwoLines = textPainter.computeLineMetrics().length > 1;
    textPainter.dispose();
    return usesTwoLines;
  }

  @override
  Widget build(BuildContext context) {
    final (background: background, foreground: foreground, icon: iconColor) = type.colors(context);

    final textStyle = TextStyle(
      color: foreground,
      decoration: TextDecoration.none,
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      fontSize: 14.5,
    );

    final neutralSolid = context.qui.colorScheme.colors.neutral.solid;
    final decoration = BoxDecoration(
      color: background,
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      boxShadow: [
        BoxShadow(
          color: neutralSolid.withValues(alpha: 0.16),
          blurRadius: 38,
          spreadRadius: -8,
          offset: const Offset(0, 18),
        ),
        BoxShadow(
          color: neutralSolid.withValues(alpha: 0.08),
          blurRadius: 12,
          spreadRadius: 4,
          offset: const Offset(0, 6),
        ),
      ],
    );

    return Semantics(
      liveRegion: true,
      label: message,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final usesTwoLines = _isUsingTwoLines(context, constraints, textStyle);

          return DecoratedBox(
            key: const Key('qui_toast_surface'),
            decoration: decoration,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                usesTwoLines ? 18 : _contentPaddingLeft,
                _contentPaddingLeft,
                _contentPaddingRight,
                _contentPaddingLeft,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Center(
                    child: SizedBox.square(
                      key: const Key('qui_toast_icon_box'),
                      dimension: _iconSize,
                      child: Align(alignment: Alignment.topLeft, child: _buildIcon(context, type, iconColor)),
                    ),
                  ),
                  const SizedBox(width: _iconTextGap),
                  Flexible(
                    child: Text(
                      message,
                      key: const Key('qui_toast_message'),
                      maxLines: _maxLines,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildIcon(BuildContext context, QuiToastType type, Color iconColor) {
    return switch (type) {
      QuiToastType.error => QuiIcons.instance.build(
        (assets) => assets.circleBlock,
        width: _iconSize,
        height: _iconSize,
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        excludeFromSemantics: true,
      ),
    };
  }
}
