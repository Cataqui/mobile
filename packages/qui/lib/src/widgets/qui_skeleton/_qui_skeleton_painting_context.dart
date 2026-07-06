part of 'qui_skeleton.dart';

class _QuiSkeletonPaintingContext extends PaintingContext {
  _QuiSkeletonPaintingContext(super.containerLayer, super.estimatedBounds, this._leafRegistry, this._skeletonPaint);

  static bool _isLeaf(RenderObject child) {
    if (child is RenderObjectWithChildMixin<RenderBox>) {
      return child.child == null;
    }

    if (child is ContainerRenderObjectMixin<RenderBox, ContainerBoxParentData<RenderBox>>) {
      return child.firstChild == null;
    }

    return true;
  }

  final _QuiSkeletonLeafRegistry _leafRegistry;
  final Paint _skeletonPaint;

  void finish() => stopRecordingIfNeeded();

  @override
  Canvas get canvas {
    return _QuiSkeletonCanvas(parent: super.canvas, leafRegistry: _leafRegistry, skeletonPaint: _skeletonPaint);
  }

  @override
  void paintChild(RenderObject child, Offset offset) {
    if (_isLeaf(child)) _leafRegistry.add(child.paintBounds.shift(offset).center);

    super.paintChild(child, offset);
  }

  @override
  PaintingContext createChildContext(ContainerLayer childLayer, Rect bounds) {
    return _QuiSkeletonPaintingContext(childLayer, bounds, _leafRegistry, _skeletonPaint);
  }
}
