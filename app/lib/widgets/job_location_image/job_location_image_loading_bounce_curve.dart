part of 'job_location_image.dart';

class _JobLocationImageLoadingBounceCurve extends Curve {
  const _JobLocationImageLoadingBounceCurve();

  @override
  double transform(double progress) => 4 * progress * (1 - progress);
}
