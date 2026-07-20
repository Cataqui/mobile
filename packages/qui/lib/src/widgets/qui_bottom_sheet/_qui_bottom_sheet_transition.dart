part of 'qui_bottom_sheet.dart';

class _QuiBottomSheetTransition extends SingleChildRenderObjectWidget {
  const _QuiBottomSheetTransition({
    required this.animation,
    required this.isInteractive,
    required super.child,
    super.key,
  });

  final Animation<double> animation;
  final ValueGetter<bool> isInteractive;

  @override
  _RenderQuiBottomSheetTransition createRenderObject(BuildContext context) {
    return _RenderQuiBottomSheetTransition(animation, isInteractive);
  }

  @override
  void updateRenderObject(BuildContext context, _RenderQuiBottomSheetTransition renderObject) {
    renderObject
      ..animation = animation
      ..isInteractive = isInteractive;
  }
}
