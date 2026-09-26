import 'package:cataqui_app/views/me/my_post/post_activation_slide_action/post_activation_landing_curve.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the slide and return stay within the track and settle softly at either end', () {
    const curve = PostActivationLandingCurve();
    var previousForward = 0.0;
    var previousReturn = 1.0;

    for (var frame = 0; frame <= 1000; frame++) {
      final progress = curve.transform(frame / 1000);
      final returnProgress = 1 - progress;
      expect(progress, inInclusiveRange(0, 1));
      expect(progress, greaterThanOrEqualTo(previousForward));
      expect(returnProgress, lessThanOrEqualTo(previousReturn));
      previousForward = progress;
      previousReturn = returnProgress;
    }

    expect(curve.transform(0), 0);
    expect(curve.transform(1), 1);

    // At 60 fps, the final frame should travel less than the old cubic ease.
    const penultimateFrame = 1 - 1 / 22;
    expect(1 - curve.transform(penultimateFrame), lessThan(1 - Curves.easeOutCubic.transform(penultimateFrame)));
  });

  test('the landing blend does not introduce a speed step', () {
    const curve = PostActivationLandingCurve();
    const handoff = 0.6;
    const sample = 0.0001;
    final before = (curve.transform(handoff) - curve.transform(handoff - sample)) / sample;
    final after = (curve.transform(handoff + sample) - curve.transform(handoff)) / sample;

    expect(after, closeTo(before, 0.001));
    expect((1 - curve.transform(0.999)) / 0.001, lessThan(0.0001));
  });
}
