import 'package:flutter/material.dart';
import 'package:qui/src/icons/qui_icons.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

import 'qui_tap/qui_tap.dart';

/// A back button designed specifically for full-view surfaces
/// (screens that occupy the entire viewport).
///
/// Unlike a generic icon button, [QuiViewBackButton] is a purpose-built
/// component with a fixed tap target and an arrow icon.
///
///
/// {@tool snippet}
/// ```dart
/// QuiViewBackButton(
///   onPressed: () => Navigator.of(context).pop(),
/// )
/// ```
/// {@end-tool}
///
class QuiViewBackButton extends StatelessWidget {
  /// Creates a QUI view back button.
  ///
  /// The [semanticLabel] defaults to `'Go back'`. Consumers should provide a
  /// localized label via their i18n system when the button is used in a
  /// non-English context.
  const QuiViewBackButton({required this.onPressed, super.key, this.semanticLabel = 'Go back'});

  /// Called when the button is pressed.
  ///
  /// Typically wired to `Navigator.of(context).pop()` or the equivalent
  /// router-level back action for the current surface.
  final VoidCallback onPressed;

  /// The accessibility label announced by screen readers.
  ///
  /// Defaults to `'Go back'`. Override with a localized string such as
  /// `'Voltar'` for Portuguese or `'Retour'` for French.
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    const shape = CircleBorder();

    return Semantics(
      key: const Key('qui_view_back_button_semantics'),
      button: true,
      enabled: true,
      label: semanticLabel,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: context.qui.colorScheme.buttons.floating.shadow, blurRadius: 24)],
        ),
        child: Material(
          color: context.qui.colorScheme.buttons.floating.background,
          shape: shape.copyWith(side: BorderSide(color: context.qui.colorScheme.buttons.floating.border)),
          clipBehavior: Clip.antiAlias,
          child: QuiTap(
            onPressed: (animation) async => onPressed(),
            animation: QuiTapAnimationType.none,
            child: SizedBox.square(
              key: const Key('qui_view_back_button_tap_target'),
              dimension: 53,
              child: Center(
                child: SizedBox.square(
                  key: const Key('qui_view_back_button_icon_box'),
                  dimension: 22,
                  child: QuiIcons.instance.build(
                    (assets) => assets.arrowLeft,
                    width: 22,
                    height: 22,
                    colorFilter: ColorFilter.mode(context.qui.colorScheme.text.primary, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
