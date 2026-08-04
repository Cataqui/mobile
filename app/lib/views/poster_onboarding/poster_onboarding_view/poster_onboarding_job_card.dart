part of 'poster_onboarding_view.dart';

class PosterOnboardingJobCard extends StatelessWidget {
  factory PosterOnboardingJobCard.waiter({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_waiter_job_preview'),
      avatar: Assets.memoji.alex.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.waiter.interest,
      rotationDegrees: 2.5,
      panelWidth: panelWidth,
      map: $Svg.map1(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_waiter_job',
      title: i18n.posterOnboarding.jobs.waiter.title,
      localizedAmount: i18n.posterOnboarding.jobs.waiter.amount,
      amountPeriod: JobPaymentAmountPeriod.daily,
      description: i18n.posterOnboarding.jobs.waiter.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.movingHelper({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_moving_helper_job_preview'),
      avatar: Assets.memoji.chris.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.movingHelper.interest,
      rotationDegrees: -1.73,
      panelWidth: panelWidth,
      map: $Svg.map2(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_moving_helper_job',
      title: i18n.posterOnboarding.jobs.movingHelper.title,
      localizedAmount: i18n.posterOnboarding.jobs.movingHelper.amount,
      amountPeriod: JobPaymentAmountPeriod.single,
      description: i18n.posterOnboarding.jobs.movingHelper.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.dogWalker({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_dog_walker_job_preview'),
      avatar: Assets.memoji.ariana.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.dogWalker.interest,
      rotationDegrees: 2.75,
      panelWidth: panelWidth,
      map: $Svg.map3(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_dog_walker_job',
      title: i18n.posterOnboarding.jobs.dogWalker.title,
      localizedAmount: i18n.posterOnboarding.jobs.dogWalker.amount,
      amountPeriod: JobPaymentAmountPeriod.daily,
      description: i18n.posterOnboarding.jobs.dogWalker.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.furnitureAssembler({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_furniture_assembler_job_preview'),
      avatar: Assets.memoji.justin.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.furnitureAssembler.interest,
      rotationDegrees: -1,
      panelWidth: panelWidth,
      map: $Svg.map4(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_furniture_assembler_job',
      title: i18n.posterOnboarding.jobs.furnitureAssembler.title,
      localizedAmount: i18n.posterOnboarding.jobs.furnitureAssembler.amount,
      amountPeriod: JobPaymentAmountPeriod.single,
      description: i18n.posterOnboarding.jobs.furnitureAssembler.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.storeAttendant({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_store_attendant_job_preview'),
      avatar: Assets.memoji.ana.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.storeAttendant.interest,
      rotationDegrees: 1.75,
      panelWidth: panelWidth,
      map: $Svg.map5(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_store_attendant_job',
      title: i18n.posterOnboarding.jobs.storeAttendant.title,
      localizedAmount: i18n.posterOnboarding.jobs.storeAttendant.amount,
      amountPeriod: JobPaymentAmountPeriod.monthly,
      description: i18n.posterOnboarding.jobs.storeAttendant.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.kitchenHelper({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_kitchen_helper_job_preview'),
      avatar: Assets.memoji.ed.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.kitchenHelper.interest,
      rotationDegrees: -2.5,
      panelWidth: panelWidth,
      map: $Svg.map6(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_kitchen_helper_job',
      title: i18n.posterOnboarding.jobs.kitchenHelper.title,
      localizedAmount: i18n.posterOnboarding.jobs.kitchenHelper.amount,
      amountPeriod: JobPaymentAmountPeriod.single,
      description: i18n.posterOnboarding.jobs.kitchenHelper.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.eventPhotographer({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_event_photographer_job_preview'),
      avatar: Assets.memoji.sabrina.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.eventPhotographer.interest,
      rotationDegrees: 0.75,
      panelWidth: panelWidth,
      map: $Svg.map1(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_event_photographer_job',
      title: i18n.posterOnboarding.jobs.eventPhotographer.title,
      localizedAmount: i18n.posterOnboarding.jobs.eventPhotographer.amount,
      amountPeriod: JobPaymentAmountPeriod.single,
      description: i18n.posterOnboarding.jobs.eventPhotographer.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.postConstructionCleaner({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_post_construction_cleaner_job_preview'),
      avatar: Assets.memoji.ryan.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.postConstructionCleaner.interest,
      rotationDegrees: 1.5,
      panelWidth: panelWidth,
      map: $Svg.map2(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_post_construction_cleaner_job',
      title: i18n.posterOnboarding.jobs.postConstructionCleaner.title,
      localizedAmount: i18n.posterOnboarding.jobs.postConstructionCleaner.amount,
      amountPeriod: JobPaymentAmountPeriod.single,
      description: i18n.posterOnboarding.jobs.postConstructionCleaner.description,
      i18n: i18n,
    );
  }

  factory PosterOnboardingJobCard.constructionHelper({required Translations i18n, required double panelWidth}) {
    return PosterOnboardingJobCard._(
      key: const ValueKey('poster_onboarding_construction_helper_job_preview'),
      avatar: Assets.memoji.stephen.image(width: 34, height: 34),
      interestLabel: i18n.posterOnboarding.jobs.constructionHelper.interest,
      rotationDegrees: -3.25,
      panelWidth: panelWidth,
      map: $Svg.map3(width: panelWidth, height: panelHeight, maintainAspectRatio: false),
      jobKey: 'poster_onboarding_construction_helper_job',
      title: i18n.posterOnboarding.jobs.constructionHelper.title,
      localizedAmount: i18n.posterOnboarding.jobs.constructionHelper.amount,
      amountPeriod: JobPaymentAmountPeriod.daily,
      description: i18n.posterOnboarding.jobs.constructionHelper.description,
      i18n: i18n,
    );
  }

  const PosterOnboardingJobCard._({
    required this.avatar,
    required this.interestLabel,
    required this.rotationDegrees,
    required this.panelWidth,
    required this.map,
    required this.jobKey,
    required this.title,
    required this.localizedAmount,
    required this.amountPeriod,
    required this.description,
    required this.i18n,
    super.key,
  }) : assert(
         rotationDegrees >= -maximumRotationDegrees && rotationDegrees <= maximumRotationDegrees,
         'Poster onboarding job-card rotation must stay within 5 degrees.',
       );

  static const panelHeight = 316.0;
  static const rotationOverflowPadding = 14.0;
  static const maximumRotationDegrees = 5.0;
  static const _mapCornerRadius = 34.0;
  static const _jobCardInset = 8.0;

  final Widget avatar;
  final String interestLabel;
  final double rotationDegrees;
  final double panelWidth;
  final Widget map;
  final String jobKey;
  final String title;
  final String localizedAmount;
  final JobPaymentAmountPeriod amountPeriod;
  final String description;
  final Translations i18n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: rotationOverflowPadding),
      child: Transform.rotate(
        angle: rotationDegrees * math.pi / 180,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMapPanel(context),
            SizedBox(key: ValueKey('${jobKey}_interest_spacing'), height: 20),
            _buildInterestBubble(context),
          ],
        ),
      ),
    );
  }

  Widget _buildMapPanel(BuildContext context) {
    return SizedBox(
      key: ValueKey('${jobKey}_map_panel'),
      width: panelWidth,
      height: panelHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_mapCornerRadius),
              child: SizedBox(width: panelWidth, height: panelHeight, child: map),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: Padding(
              key: ValueKey('${jobKey}_inset'),
              padding: const EdgeInsets.all(_jobCardInset),
              child: _buildJobDetails(context),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 72,
            child: IgnorePointer(
              child: DecoratedBox(
                key: ValueKey('${jobKey}_fade'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      context.mateo.colorScheme.background.withValues(alpha: 0),
                      context.mateo.colorScheme.background,
                    ],
                    stops: const [0, 0.9],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobDetails(BuildContext context) {
    final colorScheme = context.mateo.colorScheme;
    final amount = num.parse(localizedAmount);
    final payment = JobPaymentDto(
      type: JobPaymentType.fixed,
      minAmount: amount,
      maxAmount: amount,
      amountPeriod: amountPeriod,
      currency: i18n.posterOnboarding.jobCard.currencyCode,
      note: '',
    );

    return DecoratedBox(
      key: ValueKey('${jobKey}_card'),
      decoration: BoxDecoration(
        color: colorScheme.background,
        borderRadius: BorderRadius.circular(_mapCornerRadius - _jobCardInset),
        boxShadow: [
          BoxShadow(
            color: context.mateo.palette.neutral[12].withValues(alpha: 0.05),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              i18n.posterOnboarding.jobCard.postedTime,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: colorScheme.text.tertiary),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: colorScheme.text.primary, fontWeight: FontWeight.w600, fontSize: 16),
            ),
            Text(
              payment.formatPayment(i18n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 19, color: colorScheme.text.profit, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: colorScheme.text.secondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInterestBubble(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.4,
      child: Row(
        key: ValueKey('${jobKey}_interest'),
        mainAxisSize: MainAxisSize.min,
        children: [
          avatar,
          const SizedBox(width: 10),
          DecoratedBox(
            key: ValueKey('${jobKey}_interest_bubble'),
            decoration: BoxDecoration(
              color: context.mateo.palette.primary[9],
              borderRadius: BorderRadius.circular(999),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: Text(
                interestLabel,
                style: TextStyle(
                  color: context.mateo.colorScheme.buttons.danger.foreground,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
