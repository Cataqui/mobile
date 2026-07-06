part of 'qui_skeleton.dart';

class _QuiSkeletonLeafRegistry {
  static const double _coordinatePrecision = 10;

  static int _scaledCoordinate(double coordinate) => (coordinate * _coordinatePrecision).round();
  static int _key(int x, int y) => ((x & 0xffffffff) << 32) ^ (y & 0xffffffff);

  final Set<int> _centerKeys = <int>{};

  void add(Offset center) => _centerKeys.add(_key(_scaledCoordinate(center.dx), _scaledCoordinate(center.dy)));

  bool contains(Offset center) {
    final x = _scaledCoordinate(center.dx);
    final y = _scaledCoordinate(center.dy);

    for (var dx = -1; dx <= 1; dx++) {
      for (var dy = -1; dy <= 1; dy++) {
        if (_centerKeys.contains(_key(x + dx, y + dy))) return true;
      }
    }

    return false;
  }

  void clear() => _centerKeys.clear();
}
