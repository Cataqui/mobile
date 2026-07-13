import 'package:flutter/material.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_buttons_bar_enums.dart';

/// A pill-shaped QUI surface for grouping related button widgets.
///
/// `QuiButtonsBar` is intended for compact action clusters, such as accept and
/// dismiss controls floating over a map or feed item. The bar provides the
/// shared pill surface, inner padding, and spacing between actions while the
/// widgets passed through [items] remain responsible for their own interaction,
/// semantics, enabled state, iconography, and colors.
///
/// The bar uses `context.qui.colors.background` as its fill color so it blends
/// with the current QUI screen surface. It applies fixed inner padding and
/// spaces row items evenly according to the QUI button-group layout.
///
/// Width is controlled by [widthFit]:
///
///  * [QuiButtonsBarFit.fitItems] keeps the bar as narrow as its padded items.
///  * [QuiButtonsBarFit.expand] expands the bar to the finite maximum width
///    available from the parent layout or from [constraints].
///
/// Height is intentionally not controlled by a fit option. By default the bar
/// sizes its height to its padded items. To force a specific height, pass a
/// finite height through [constraints].
///
/// When [widthFit] is [QuiButtonsBarFit.expand] and neither the parent nor
/// [constraints] provides a finite maximum width, the widget throws a
/// [FlutterError]. This mirrors Flutter's constraint model and avoids guessing
/// a viewport-sized width in unbounded layouts.
class QuiButtonsBar extends StatefulWidget {
  /// Creates a QUI buttons bar.
  ///
  /// The [items] list must contain at least one widget. The widget does not
  /// clone, wrap, or modify the items beyond placing them inside the bar, so
  /// callers should pass fully configured button widgets.
  const QuiButtonsBar({
    required this.items,
    super.key,
    this.orientation = QuiButtonsBarOrientation.row,
    this.constraints,
    this.widthFit = QuiButtonsBarFit.fitItems,
  }) : assert(items.length > 0, 'QuiButtonsBar requires at least one item.');

  /// Button widgets displayed inside the bar.
  ///
  /// Items are laid out according to [orientation]. Each item keeps its own
  /// sizing, semantics, gestures, and visual state.
  final List<Widget> items;

  /// Layout direction used to arrange [items].
  final QuiButtonsBarOrientation orientation;

  /// Optional size constraints applied to the outer bar.
  ///
  /// Constraints are applied after the width fit is resolved. Use this to set a
  /// fixed width or height, or to provide a finite maximum width for
  /// [QuiButtonsBarFit.expand] in otherwise unbounded layouts.
  final BoxConstraints? constraints;

  /// Controls how the bar resolves its width.
  ///
  /// The default, [QuiButtonsBarFit.fitItems], keeps the bar shrink-wrapped to
  /// its padded row content. [QuiButtonsBarFit.expand] fills the available
  /// finite maximum width while still respecting [constraints].
  final QuiButtonsBarFit widthFit;

  @override
  State<QuiButtonsBar> createState() => _QuiButtonsBarState();
}

class _QuiButtonsBarState extends State<QuiButtonsBar> with SingleTickerProviderStateMixin {
  static const _maxTiltAngle = 0.8;
  static const _perspectiveValue = 0.002;
  static const _tiltInDuration = Duration(milliseconds: 100);
  static const _tiltOutDuration = Duration(milliseconds: 600);

  late final AnimationController _tiltController;
  late final CurvedAnimation _tiltAnimation;
  static const _referenceBarWidth = 174.0;

  double _tiltX = 0;
  double _barWidth = 0;
  int _activePointers = 0;

  double? _expandedWidth({
    required QuiButtonsBarFit fit,
    required double parentMaxSize,
    required double? configuredMaxSize,
  }) {
    if (fit == QuiButtonsBarFit.fitItems) return null;

    final availableMaxSize = _availableMaxSize(parentMaxSize: parentMaxSize, configuredMaxSize: configuredMaxSize);
    if (!availableMaxSize.isFinite) {
      throw FlutterError(
        'QuiButtonsBar cannot expand its width without a finite maximum width. '
        'Wrap it in a widget that provides bounded width constraints or pass '
        'constraints with a finite maxWidth.',
      );
    }

    return availableMaxSize;
  }

  double _availableMaxSize({required double parentMaxSize, required double? configuredMaxSize}) {
    final hasConfiguredMaxSize = configuredMaxSize != null && configuredMaxSize.isFinite;

    if (hasConfiguredMaxSize && parentMaxSize.isFinite) {
      return configuredMaxSize < parentMaxSize ? configuredMaxSize : parentMaxSize;
    }

    if (hasConfiguredMaxSize) return configuredMaxSize;

    return parentMaxSize;
  }

  void _onPointerDown(PointerDownEvent event) {
    _activePointers++;

    final renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return;

    _barWidth = renderObject.size.width;

    final localPosition = renderObject.globalToLocal(event.position);

    setState(() {
      _tiltX = (localPosition.dx / _barWidth * 2 - 1).clamp(-1.0, 1.0);
    });

    _tiltController.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    _activePointers--;
    if (_activePointers > 0) return;
    if (mounted) _tiltController.reverse();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _activePointers = 0;
    if (mounted) _tiltController.reverse();
  }

  void _onTiltStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed) {
      _tiltX = 0;
    }
  }

  Widget _content() {
    return switch (widget.orientation) {
      QuiButtonsBarOrientation.row => Row(mainAxisSize: MainAxisSize.min, spacing: 40, children: widget.items),
    };
  }

  @override
  void initState() {
    super.initState();
    _tiltController = AnimationController(vsync: this, duration: _tiltInDuration, reverseDuration: _tiltOutDuration);
    _tiltAnimation = CurvedAnimation(
      parent: _tiltController,
      curve: Curves.decelerate,
      reverseCurve: Curves.decelerate,
    );
    _tiltController.addStatusListener(_onTiltStatusChanged);
  }

  @override
  void dispose() {
    _tiltController.removeStatusListener(_onTiltStatusChanged);
    _tiltAnimation.dispose();
    _tiltController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableTilt = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, parentConstraints) {
        final resolvedConstraints = widget.constraints;

        // Wrap the content bar container directly
        final Widget content = Container(
          key: const Key('qui_buttons_bar_container'),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.qui.colorScheme.background,
            borderRadius: BorderRadius.circular(9999),
          ),
          child: Align(
            widthFactor: 1,
            heightFactor: 1,
            child: _content(), // Contains your button items
          ),
        );

        Widget bar = SizedBox(
          width: _expandedWidth(
            fit: widget.widthFit,
            parentMaxSize: parentConstraints.maxWidth,
            configuredMaxSize: resolvedConstraints?.maxWidth,
          ),
          child: content,
        );

        if (resolvedConstraints != null) bar = ConstrainedBox(constraints: resolvedConstraints, child: bar);

        if (!disableTilt) {
          bar = AnimatedBuilder(
            animation: _tiltAnimation,
            builder: (context, child) {
              final progress = _tiltAnimation.value;

              final Matrix4 matrix;

              if (progress == 0) {
                matrix = Matrix4.identity();
              } else {
                final safeBarWidth = _barWidth > 0 ? _barWidth : _referenceBarWidth;
                final ratio = (_referenceBarWidth / safeBarWidth).clamp(0.0, 1.0);
                final widthFactor = ratio * ratio;
                final angle = -_maxTiltAngle * _tiltX * progress * widthFactor;

                matrix = Matrix4.identity()
                  ..setEntry(3, 2, _perspectiveValue)
                  ..rotateY(angle);
              }

              final opacity = 1.0 - progress * 0.18;

              // 2. PRODUCTION OPTIMIZATION: We keep the tree structure identical at all times,
              // but we use ColorFiltered instead of Opacity. ColorFiltered updates the alpha channel
              // directly on the GPU without creating an expensive offscreen saveLayer buffer.
              return Transform(
                transform: matrix,
                alignment: Alignment.center,
                child: ColorFiltered(
                  colorFilter: ColorFilter.matrix(<double>[
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    opacity,
                    0,
                  ]),
                  child: child,
                ),
              );
            },
            child: bar,
          );

          bar = Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onPointerDown,
            onPointerUp: _onPointerUp,
            onPointerCancel: _onPointerCancel,
            child: bar,
          );
        }

        return bar;
      },
    );
  }
}
