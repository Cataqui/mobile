library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'package:qui/src/theme/qui_theme.dart';

part 'qui_orbit_enums.dart';
part 'qui_orbit_flow_delegate.dart';
part 'qui_orbit_item.dart';
part 'qui_orbit_item_data.dart';

/// A slowly rotating circle of widgets, a planetary orbit.
///
/// [items] are placed evenly around a circle and revolve around the center.
/// Each item independently traces its own circular path around the center
/// (the group does not rotate as a rigid body). Set [rotateItems] to `false`
/// to make items stay upright (counter-rotated) so content stays readable.
///
/// The orbit requires **at least 4 items** (enforced by `assert`).
///
/// ```dart
/// QuiOrbit(
///   items: [
///     QuiOrbitItem(child: Icon(Icons.bolt_rounded), size: const Size(64, 64)),
///     QuiOrbitItem(child: Icon(Icons.restaurant_rounded), size: const Size(64, 64)),
///     QuiOrbitItem(child: Icon(Icons.delivery_dining_rounded), size: const Size(64, 64)),
///     QuiOrbitItem(child: Icon(Icons.cleaning_services_rounded), size: const Size(64, 64)),
///   ],
/// )
/// ```
class QuiOrbit extends StatefulWidget {
  /// Creates a QUI orbiting circle of widgets.
  ///
  /// Requires at least 4 [items] (enforced by `assert` in debug mode).
  const QuiOrbit({
    required this.items,
    super.key,
    this.radius,
    this.revolutionDuration = const Duration(seconds: 30),
    this.direction = QuiOrbitDirection.clockwise,
    this.rotateItems = false,
    this.initialAngle = 0,
    this.padding = 0,
  }) : assert(items.length >= 4, 'QuiOrbit requires at least 4 items, but got ${items.length}.');

  /// The widgets placed around the orbit. Must contain at least 4 entries.
  final List<QuiOrbitItem> items;

  /// Explicit orbit radius applied from the center to each item's center.
  ///
  /// When `null`, the radius is auto-computed from the available size and
  /// the largest item's half-diagonal so every item fits fully on-screen.
  final double? radius;

  /// Time for one full revolution. Defaults to 30 seconds (slow, premium).
  final Duration revolutionDuration;

  /// Rotation direction.
  final QuiOrbitDirection direction;

  /// Whether items rotate to face the orbit center (`true`) or stay upright
  /// (`false`, the default).
  ///
  /// When `true`, each item rotates around its own center as it orbits,
  /// so the item's content always points toward (or away from) the orbit
  /// center — like items on a carousel. When `false`, each item stays
  /// upright and its content remains readable regardless of position.
  final bool rotateItems;

  /// Starting rotation offset in radians. Defaults to `0`.
  final double initialAngle;

  /// Extra inset subtracted from the auto-computed radius.
  ///
  /// Ignored when [radius] is explicitly provided. Defaults to `0`.
  final double padding;

  @override
  State<QuiOrbit> createState() => _QuiOrbitState();
}

class _QuiOrbitState extends State<QuiOrbit> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: widget.revolutionDuration);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncControllerState();
  }

  @override
  void didUpdateWidget(covariant QuiOrbit oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.revolutionDuration != oldWidget.revolutionDuration) {
      _animationController.duration = widget.revolutionDuration;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _animationController.stop();
    } else if (state == AppLifecycleState.resumed) {
      _syncControllerState();
    }
  }

  void _syncControllerState() {
    final disabled = MediaQuery.disableAnimationsOf(context);

    if (disabled) {
      if (_animationController.isAnimating) _animationController.stop();
    } else if (!_animationController.isAnimating) {
      _animationController.repeat();
    }
  }

  List<_QuiOrbitItemData> _computePlacements() {
    final count = widget.items.length;
    final placements = <_QuiOrbitItemData>[];

    for (var i = 0; i < count; i++) {
      final item = widget.items[i];
      final angle = (2 * math.pi / count) * i + widget.initialAngle;

      placements.add(
        _QuiOrbitItemData(
          size: item.size,
          cosBase: math.cos(angle),
          sinBase: math.sin(angle),
          cachedChild: RepaintBoundary(
            key: ValueKey(i),
            child: SizedBox(width: item.size.width, height: item.size.height, child: item.child),
          ),
        ),
      );
    }

    return placements;
  }

  @override
  Widget build(BuildContext context) {
    final disabled = MediaQuery.disableAnimationsOf(context);

    if (disabled) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final placements = _computePlacements();
          final width = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
          final height = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
          final centerX = width / 2;
          final centerY = height / 2;

          return SizedBox(
            width: width,
            height: height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                for (var index = 0; index < placements.length; index++)
                  Positioned(
                    key: ValueKey(index),
                    left:
                        centerX +
                        _orbitRadius(constraints) * placements[index].cosBase -
                        placements[index].size.width / 2,
                    top:
                        centerY +
                        _orbitRadius(constraints) * placements[index].sinBase -
                        placements[index].size.height / 2,
                    child: placements[index].cachedChild,
                  ),
              ],
            ),
          );
        },
      );
    }

    final revSign = widget.direction == QuiOrbitDirection.clockwise ? 1.0 : -1.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final placements = _computePlacements();
        final w = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final h = constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0;
        return SizedBox(
          width: w,
          height: h,
          child: Flow(
            clipBehavior: Clip.none,
            delegate: _QuiOrbitFlowDelegate(
              animation: _animationController,
              placements: placements,
              radius: _orbitRadius(constraints),
              rotationDirection: revSign,
              rotateItems: widget.rotateItems,
              animationsDisabled: disabled,
            ),
            children: [for (final placement in placements) placement.cachedChild],
          ),
        );
      },
    );
  }

  double _orbitRadius(BoxConstraints constraints) {
    const defaultSize = 300.0;
    final w = constraints.maxWidth.isFinite ? constraints.maxWidth : defaultSize;
    final h = constraints.maxHeight.isFinite ? constraints.maxHeight : defaultSize;

    double maxHalfDiagonal = 0;

    for (final item in widget.items) {
      final halfDiag = math.sqrt(item.size.width * item.size.width + item.size.height * item.size.height) / 2;
      if (halfDiag > maxHalfDiagonal) maxHalfDiagonal = halfDiag;
    }

    final radius = widget.radius ?? (math.min(w, h) / 2 - maxHalfDiagonal - widget.padding);
    return radius < 0 ? 0.0 : radius;
  }
}

@Preview(name: 'QuiOrbit', group: 'Orbits')
Widget quiOrbitPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: const Color(0xFFF6F4F1),
      body: Center(
        child: SizedBox(
          width: 360,
          height: 360,
          child: QuiOrbit(
            items: const [
              QuiOrbitItem(child: _PreviewChip(Icons.bolt_rounded, Color(0xFFFF4A4B)), size: Size(64, 64)),
              QuiOrbitItem(child: _PreviewChip(Icons.restaurant_rounded, Color(0xFF00A896)), size: Size(64, 64)),
              QuiOrbitItem(child: _PreviewChip(Icons.delivery_dining_rounded, Color(0xFF3D5A80)), size: Size(64, 64)),
              QuiOrbitItem(child: _PreviewChip(Icons.cleaning_services_rounded, Color(0xFFF4A261)), size: Size(64, 64)),
              QuiOrbitItem(child: _PreviewChip(Icons.handyman_rounded, Color(0xFF8338EC)), size: Size(64, 64)),
              QuiOrbitItem(
                child: _PreviewChip(Icons.local_laundry_service_rounded, Color(0xFF06A77D)),
                size: Size(64, 64),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PreviewChip extends StatelessWidget {
  const _PreviewChip(this.icon, this.color);

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 12, offset: Offset(0, 6))],
      ),
      child: Icon(icon, color: Colors.white, size: 28),
    );
  }
}
