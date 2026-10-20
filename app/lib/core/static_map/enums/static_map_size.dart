enum StaticMapSize {
  square(width: 480, height: 480),
  tall(width: 480, height: 1280);

  const StaticMapSize({required this.width, required this.height});
  final int width;
  final int height;
  String get value => '${width}x$height';
}
