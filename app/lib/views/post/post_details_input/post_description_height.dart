part of 'post_details_input.dart';

class _PostDescriptionHeight extends SingleChildRenderObjectWidget {
  const _PostDescriptionHeight({
    required this.duration,
    required this.curve,
    required this.vsync,
    required this.animationsDisabled,
    super.child,
  });

  final Duration duration;
  final Curve curve;
  final TickerProvider vsync;
  final bool animationsDisabled;

  @override
  _RenderPostDescriptionHeight createRenderObject(BuildContext context) {
    return _RenderPostDescriptionHeight(
      duration: duration,
      curve: curve,
      vsync: vsync,
      animationsDisabled: animationsDisabled,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderPostDescriptionHeight renderObject) {
    renderObject
      ..duration = duration
      ..curve = curve
      ..vsync = vsync
      ..animationsDisabled = animationsDisabled;
  }
}
