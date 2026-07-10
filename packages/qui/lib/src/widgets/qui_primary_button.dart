import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:qui/src/enums/qui_button_alignment.dart';
import 'package:qui/src/enums/qui_button_fit.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:qui/src/widgets/qui_dot_loading_indicator/qui_dot_loading_indicator.dart';
import 'package:qui/src/widgets/qui_tap_animation.dart';

part 'qui_primary_button_types.dart';

/// A primary action button for the QUI design system.
///
/// ```dart
/// QuiPrimaryButton(
///   label: 'Ver oportunidades',
///   onPressed: () {},
/// )
/// ```
class QuiPrimaryButton extends StatefulWidget {
  /// Creates a QUI primary button.
  const QuiPrimaryButton({
    required this.label,
    super.key,
    this.onPressed,
    this.leadingIconBuilder,
    this.trailingIconBuilder,
    this.leadingIconSpacing = 8,
    this.trailingIconSpacing = 8,
    this.backgroundColor,
    this.disabledBackgroundColor,
    this.foregroundColor,
    this.disabledForegroundColor,
    this.alignment = QuiButtonAlignment.center,
    this.fit = QuiButtonFit.fit,
    this.padding = const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
  });

  /// Visible button label.
  final String label;

  /// Called when the button is pressed.
  ///
  /// If the callback returns a [Future], the button shows a loading indicator
  /// while that future is pending. Synchronous callbacks keep the current
  /// immediate feedback and do not enter the loading state.
  ///
  /// When null, the button renders disabled and ignores pointer input.
  final FutureOr<void> Function()? onPressed;

  /// Optional icon rendered before [label].
  final QuiPrimaryButtonIconBuilder? leadingIconBuilder;

  /// Optional icon rendered after [label].
  final QuiPrimaryButtonIconBuilder? trailingIconBuilder;

  /// Horizontal spacing between [leadingIconBuilder]'s icon and [label].
  final double leadingIconSpacing;

  /// Horizontal spacing between [label] and [trailingIconBuilder]'s icon.
  final double trailingIconSpacing;

  /// Filled background color when enabled.
  ///
  /// Defaults to `context.qui.colors.primary`.
  final Color? backgroundColor;

  /// Filled background color when disabled.
  ///
  /// Defaults to `context.qui.colors.disabledButtonBackground`.
  final Color? disabledBackgroundColor;

  /// Label and recommended icon color when enabled.
  ///
  /// Defaults to [Colors.white].
  final Color? foregroundColor;

  /// Label and recommended icon color when disabled.
  ///
  /// Defaults to `context.qui.colors.disabledButtonForeground`.
  final Color? disabledForegroundColor;

  /// Controls the horizontal alignment of the label and icons within the
  /// button bounds.
  ///
  /// Only has a visible effect when [fit] is [QuiButtonFit.expand],
  /// since a shrink-wrapped button is exactly as wide as its content.
  ///
  /// Defaults to [QuiButtonAlignment.center].
  final QuiButtonAlignment alignment;

  /// Controls the width sizing behavior.
  ///
  /// [QuiButtonFit.fit] shrink-wraps the button to its content.
  /// [QuiButtonFit.expand] fills the available horizontal width.
  final QuiButtonFit fit;

  /// Insets applied inside the button around the label, icons, and loader.
  ///
  /// Defaults to the standard QUI primary button padding.
  final EdgeInsetsGeometry padding;

  @override
  State<QuiPrimaryButton> createState() => _QuiPrimaryButtonState();
}

class _QuiPrimaryButtonState extends State<QuiPrimaryButton> with SingleTickerProviderStateMixin {
  static const Duration _loadingDelay = Duration(milliseconds: 50);
  static const Duration _contentTransitionDuration = Duration(milliseconds: 300);
  static const TextStyle _baseLabelStyle = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);
  static const BorderRadius _pillBorderRadius = BorderRadius.all(Radius.circular(9999));

  late final AnimationController _contentOpacityController;
  final GlobalKey<State<StatefulWidget>> _loadingIndicatorKey = GlobalKey();

  bool _isLoading = false;
  bool _isPendingPress = false;
  bool _showLoadingIndicator = false;
  bool _showTransitionOverlay = false;
  int _pressGeneration = 0;

  bool get _isEnabled => widget.onPressed != null;
  bool get _isInteractive => _isEnabled && !_isPendingPress;

  Future<void> _handlePressed(Future<void> _) async {
    final onPressed = widget.onPressed;
    if (onPressed == null) return;

    final result = onPressed();

    if (result is! Future<void>) return;
    if (!mounted) return;

    final generation = _pressGeneration + 1;
    _pressGeneration = generation;

    setState(() => _isPendingPress = true);

    var isPending = true;
    unawaited(_showLoadingAfterDelay(generation: generation, isPending: () => isPending));

    try {
      await result;
    } finally {
      isPending = false;
      await _restoreContentAfterLoading(generation: generation);
    }
  }

  Future<void> _showLoadingAfterDelay({required int generation, required bool Function() isPending}) async {
    await Future<void>.delayed(_loadingDelay);

    if (!mounted || _pressGeneration != generation || !isPending()) return;
    if (_isLoading) return;

    _contentOpacityController
      ..stop(canceled: false)
      ..value = 1;

    setState(() => _isLoading = true);

    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() => _showLoadingIndicator = true);

      return;
    }

    await _contentOpacityController.reverse();

    if (!mounted || _pressGeneration != generation || !isPending()) return;
    if (_showLoadingIndicator) return;

    setState(() => _showLoadingIndicator = true);
  }

  Future<void> _restoreContentAfterLoading({required int generation}) async {
    if (!mounted || _pressGeneration != generation) return;

    if (!_isLoading) {
      setState(() => _isPendingPress = false);

      return;
    }

    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _isLoading = false;
        _isPendingPress = false;
        _showLoadingIndicator = false;
        _showTransitionOverlay = false;
      });

      return;
    }

    _contentOpacityController
      ..stop(canceled: false)
      ..value = 0;

    setState(() => _showTransitionOverlay = true);

    await Future<void>.delayed(_contentTransitionDuration * 3 ~/ 4);

    if (!mounted || _pressGeneration != generation) return;

    setState(() {
      _showTransitionOverlay = false;
      _showLoadingIndicator = false;
    });

    _contentOpacityController.stop(canceled: false);
    await _contentOpacityController.forward();

    if (!mounted || _pressGeneration != generation) return;

    setState(() {
      _isLoading = false;
      _isPendingPress = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _contentOpacityController = AnimationController(duration: _contentTransitionDuration, value: 1, vsync: this);
  }

  @override
  void dispose() {
    _contentOpacityController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.qui.colors;
    final isEnabled = _isEnabled;
    final isInteractive = _isInteractive;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final resolvedBackground = isEnabled
        ? widget.backgroundColor ?? colors.primary
        : widget.disabledBackgroundColor ?? colors.disabledButtonBackground;

    final resolvedForeground = isEnabled
        ? widget.foregroundColor ?? Colors.white
        : widget.disabledForegroundColor ?? colors.disabledButtonForeground;

    final labelStyle = _baseLabelStyle.copyWith(color: resolvedForeground);

    final content = _buildContent(isEnabled: isEnabled, foregroundColor: resolvedForeground, labelStyle: labelStyle);

    final animatedContent = _buildAnimatedContent(
      content: content,
      foregroundColor: resolvedForeground,
      disableAnimations: disableAnimations,
    );

    final innerContent = widget.fit == QuiButtonFit.expand ? _alignedContent(animatedContent) : animatedContent;

    final padded = Padding(
      key: const Key('qui_primary_button_container'),
      padding: widget.padding,
      child: innerContent,
    );

    final decorated = DecoratedBox(
      decoration: BoxDecoration(color: resolvedBackground, borderRadius: _pillBorderRadius),
      child: padded,
    );

    final button = widget.fit == QuiButtonFit.expand
        ? ConstrainedBox(
            constraints: const BoxConstraints.tightFor(width: double.infinity),
            child: decorated,
          )
        : decorated;

    return Semantics(
      button: true,
      enabled: isInteractive,
      onTap: isInteractive ? () => unawaited(_handlePressed(Future<void>.value())) : null,
      child: QuiTapAnimation(
        onPressed: isInteractive ? _handlePressed : null,
        animation: QuiTapAnimationType.scaleFade,
        child: button,
      ),
    );
  }

  Widget _buildContent({required bool isEnabled, required Color foregroundColor, required TextStyle labelStyle}) {
    final content = Text(widget.label, style: labelStyle);

    final iconState = QuiPrimaryButtonIconState(isEnabled: isEnabled, foregroundColor: foregroundColor);

    final hasLeading = widget.leadingIconBuilder != null;
    final hasTrailing = widget.trailingIconBuilder != null;

    if (hasLeading || hasTrailing) {
      final children = <Widget>[];

      if (hasLeading) {
        children.add(
          Padding(
            padding: EdgeInsets.only(right: widget.leadingIconSpacing),
            child: widget.leadingIconBuilder!(iconState),
          ),
        );
      }
      children.add(content);

      if (hasTrailing) {
        children.add(
          Padding(
            padding: EdgeInsets.only(left: widget.trailingIconSpacing),
            child: widget.trailingIconBuilder!(iconState),
          ),
        );
      }
      return Row(mainAxisSize: MainAxisSize.min, children: children);
    }

    return content;
  }

  Widget _buildAnimatedContent({
    required Widget content,
    required Color foregroundColor,
    required bool disableAnimations,
  }) {
    if (disableAnimations) {
      if (_showLoadingIndicator) return QuiDotLoadingIndicator(color: foregroundColor, dotRadius: 4);
      return content;
    }

    return AnimatedSize(
      duration: _contentTransitionDuration,
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: _showTransitionOverlay
          ? Stack(
              alignment: Alignment.center,
              children: <Widget>[
                FadeTransition(opacity: _contentOpacityController, child: content),
                QuiDotLoadingIndicator(key: _loadingIndicatorKey, color: foregroundColor, dotRadius: 4),
              ],
            )
          : _showLoadingIndicator
          ? QuiDotLoadingIndicator(key: _loadingIndicatorKey, color: foregroundColor, dotRadius: 4)
          : FadeTransition(opacity: _contentOpacityController, child: content),
    );
  }

  Widget _alignedContent(Widget content) {
    switch (widget.alignment) {
      case QuiButtonAlignment.left:
        return Align(alignment: Alignment.centerLeft, heightFactor: 1, child: content);
      case QuiButtonAlignment.center:
        return Align(alignment: Alignment.center, heightFactor: 1, child: content);
      case QuiButtonAlignment.right:
        return Align(alignment: Alignment.centerRight, heightFactor: 1, child: content);
    }
  }
}

/// Preview of the [QuiPrimaryButton] widget.
@Preview(name: 'QuiPrimaryButton', group: 'Buttons')
Widget quiPrimaryButtonPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            QuiPrimaryButton(label: 'Ver oportunidades', onPressed: () {}),
            const SizedBox(height: 20),
            QuiPrimaryButton(
              label: 'Buscar',
              leadingIconBuilder: (QuiPrimaryButtonIconState state) =>
                  Icon(Icons.search, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiPrimaryButton(
              label: 'Continuar',
              trailingIconBuilder: (QuiPrimaryButtonIconState state) =>
                  Icon(Icons.arrow_forward, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiPrimaryButton(
              label: 'Filtrar',
              leadingIconBuilder: (QuiPrimaryButtonIconState state) =>
                  Icon(Icons.tune, color: state.foregroundColor, size: 20),
              trailingIconBuilder: (QuiPrimaryButtonIconState state) =>
                  Icon(Icons.arrow_drop_down, color: state.foregroundColor, size: 20),
              onPressed: () {},
            ),
            const SizedBox(height: 20),
            QuiPrimaryButton(
              label: 'Indisponivel',
              leadingIconBuilder: (QuiPrimaryButtonIconState state) =>
                  Icon(Icons.lock, color: state.foregroundColor, size: 20),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              child: QuiPrimaryButton(label: 'Expandido', fit: QuiButtonFit.expand, onPressed: () {}),
            ),
            const SizedBox(height: 20),
            QuiPrimaryButton(label: 'Enviar', onPressed: () => Future<void>.delayed(const Duration(seconds: 2))),
            const SizedBox(height: 20),
            QuiPrimaryButton(
              label: 'Mapa',
              backgroundColor: const Color(0xFF00A676),
              foregroundColor: Colors.white,
              leadingIconBuilder: (QuiPrimaryButtonIconState state) =>
                  const Icon(Icons.location_on, size: 20, color: Color(0xFF00A676)),
              onPressed: () {},
            ),
          ],
        ),
      ),
    ),
  );
}
