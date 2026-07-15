part of 'app_animated_splash.dart';

class _SplashLogoPainter extends CustomPainter {
  const _SplashLogoPainter(this.pictureInfo);

  final PictureInfo pictureInfo;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..scale(size.width / pictureInfo.size.width, size.height / pictureInfo.size.height)
      ..drawPicture(pictureInfo.picture);
  }

  @override
  bool shouldRepaint(_SplashLogoPainter oldDelegate) {
    return pictureInfo != oldDelegate.pictureInfo;
  }
}
