enum StaticMapSize {
  pixels960x960(logicalSize: '480x480'),
  pixels960x2560(logicalSize: '480x1280');

  const StaticMapSize({required this.logicalSize});

  final String logicalSize;
}
