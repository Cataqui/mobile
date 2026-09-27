part of 'my_posts_carousel.dart';

class _MyPostsDrag implements Drag {
  _MyPostsDrag(this._delegate);

  static const _flingVelocityMultiplier = 1.4;

  final Drag _delegate;

  @override
  void update(DragUpdateDetails details) => _delegate.update(details);

  @override
  void end(DragEndDetails details) => _delegate.end(
    DragEndDetails(
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
      velocity: Velocity(pixelsPerSecond: details.velocity.pixelsPerSecond * _flingVelocityMultiplier),
      primaryVelocity: details.primaryVelocity == null ? null : details.primaryVelocity! * _flingVelocityMultiplier,
    ),
  );

  @override
  void cancel() => _delegate.cancel();
}
