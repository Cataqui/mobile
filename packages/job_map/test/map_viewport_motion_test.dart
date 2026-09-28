import 'package:flutter_test/flutter_test.dart';
import 'package:job_map/src/map_viewport_motion.dart';

void main() {
  test('fast swipes prepare farther ahead when Google takes longer to produce a map', () {
    final motion = MapViewportMotion()
      ..update(position: 2, timestamp: Duration.zero)
      ..update(position: 2.6, timestamp: const Duration(milliseconds: 50));

    expect(motion.distanceAfter(const Duration(milliseconds: 250)), 3);
    expect(motion.distanceAfter(const Duration(milliseconds: 750)), 9);
  });

  test('reversing a swipe immediately prepares maps in the new direction', () {
    final motion = MapViewportMotion()
      ..update(position: 2, timestamp: Duration.zero)
      ..update(position: 2.6, timestamp: const Duration(milliseconds: 50))
      ..update(position: 2.2, timestamp: const Duration(milliseconds: 100));

    expect(motion.distanceAfter(const Duration(milliseconds: 500)), -4);
    motion.reset();
    expect(motion.distanceAfter(const Duration(seconds: 1)), 0);
  });

  test('slow motion permits map details while a fast or fresh drag defers them', () {
    final motion = MapViewportMotion();
    expect(motion.shouldDeferFullCapture(at: Duration.zero), isTrue);

    motion.update(position: 0, timestamp: Duration.zero);
    expect(motion.shouldDeferFullCapture(at: Duration.zero), isTrue);

    motion.update(position: .05, timestamp: const Duration(milliseconds: 100));
    expect(motion.shouldDeferFullCapture(at: const Duration(milliseconds: 100)), isFalse);

    motion.update(position: .45, timestamp: const Duration(milliseconds: 150));
    expect(motion.shouldDeferFullCapture(at: const Duration(milliseconds: 150)), isTrue);
    expect(motion.shouldDeferFullCapture(at: const Duration(milliseconds: 270)), isFalse);
  });

  test('transit skipping starts only when cards pass too quickly to inspect', () {
    final motion = MapViewportMotion()
      ..update(position: 0, timestamp: Duration.zero)
      ..update(position: .3, timestamp: const Duration(milliseconds: 100));
    expect(motion.isFastTransitAt(at: const Duration(milliseconds: 100)), isFalse);

    motion.update(position: .8, timestamp: const Duration(milliseconds: 150));
    expect(motion.isFastTransitAt(at: const Duration(milliseconds: 150)), isTrue);
    expect(motion.isFastTransitAt(at: const Duration(milliseconds: 270)), isFalse);

    motion.update(position: .82, timestamp: const Duration(milliseconds: 350));
    expect(motion.isFastTransitAt(at: const Duration(milliseconds: 350)), isFalse);
  });
}
