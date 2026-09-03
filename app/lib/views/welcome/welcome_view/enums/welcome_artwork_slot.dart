enum WelcomeArtworkSlot {
  top(leftInset: 111, topOffset: 53, floatingDistance: 5, floatingDuration: Duration(milliseconds: 2600)),
  rightTopCorner(
    rightInset: 5,
    topOffset: 82,
    floatingDistance: 5,
    floatingDelay: Duration(milliseconds: 360),
    floatingDuration: Duration(milliseconds: 2450),
  ),
  leftBottomCorner(
    leftInset: 5,
    topOffset: 272,
    floatingDistance: 6,
    floatingDelay: Duration(milliseconds: 520),
    floatingDuration: Duration(milliseconds: 2700),
  ),
  bottom(
    leftInset: 186,
    bottomOffset: 7,
    floatingDistance: 4,
    floatingDelay: Duration(milliseconds: 740),
    floatingDuration: Duration(milliseconds: 2500),
  ),
  rightBottomCorner(
    rightInset: 5,
    topOffset: 292,
    floatingDistance: 7,
    floatingDelay: Duration(milliseconds: 880),
    floatingDuration: Duration(milliseconds: 2900),
  );

  const WelcomeArtworkSlot({
    required this.floatingDistance,
    required this.floatingDuration,
    this.topOffset,
    this.bottomOffset,
    this.leftInset,
    this.rightInset,
    this.floatingDelay = Duration.zero,
  }) : assert((leftInset == null) != (rightInset == null), 'Exactly one horizontal inset is required.'),
       assert((topOffset == null) != (bottomOffset == null), 'Exactly one vertical offset is required.');

  final double? leftInset;
  final double? rightInset;
  final double? topOffset;
  final double? bottomOffset;
  final double floatingDistance;
  final Duration floatingDelay;
  final Duration floatingDuration;

  double resolveLeft({required double sceneWidth, required double surfaceSize}) {
    if (leftInset case final leftInset?) return leftInset;
    return sceneWidth - rightInset! - surfaceSize;
  }

  double resolveTop({required double sceneHeight, required double surfaceSize, required double topTrim}) {
    if (topOffset case final topOffset?) return topOffset - topTrim;
    return sceneHeight - bottomOffset! - surfaceSize;
  }
}
