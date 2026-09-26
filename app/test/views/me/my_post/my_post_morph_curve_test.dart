import 'package:cataqui_app/views/me/my_post/my_post_morph_curve.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('My Post Morph moves promptly and lands without overshoot or a visible final step', () {
    const curve = MyPostMorphCurve();
    expect(curve.transform(0), 0);
    expect(curve.transform(1), 1);
    expect(curve.transform(0.25), greaterThan(0.4));

    var previous = curve.transform(0);
    for (var sample = 1; sample <= 1000; sample++) {
      final progress = curve.transform(sample / 1000);
      expect(progress, inInclusiveRange(previous, 1));
      previous = progress;
    }

    var previousStep = curve.transform(0.16) - curve.transform(0.159);
    for (var sample = 161; sample <= 1000; sample++) {
      final step = curve.transform(sample / 1000) - curve.transform((sample - 1) / 1000);
      expect(step, lessThanOrEqualTo(previousStep + 0.00000001));
      previousStep = step;
    }

    final finalFrameTravel = 600 * (1 - curve.transform(1 - 1 / 27));
    expect(finalFrameTravel, lessThan(0.05));
  });
}
