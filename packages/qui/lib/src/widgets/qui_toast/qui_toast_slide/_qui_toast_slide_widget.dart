part of '../qui_toast.dart';

class _QuiToastSlideWidget extends SingleChildRenderObjectWidget {
  const _QuiToastSlideWidget({required this.position, required super.child});

  final Animation<Offset>? position;

  @override
  _RenderQuiToastSlide createRenderObject(BuildContext context) {
    return _RenderQuiToastSlide(position: position);
  }

  @override
  void updateRenderObject(BuildContext context, covariant _RenderQuiToastSlide renderObject) {
    renderObject.position = position;
  }
}
