part of 'poster_onboarding_view.dart';

class PosterOnboardingJobScene extends StatelessWidget {
  const PosterOnboardingJobScene({required this.i18n, required this.viewportWidth, super.key});

  static const _jobRowTop = 24.0;
  static const _jobSceneHeight = 420.0;

  final Translations i18n;
  final double viewportWidth;

  @override
  Widget build(BuildContext context) {
    final sceneWidth = math.min(viewportWidth, PosterOnboardingView.maximumContentWidth);
    final panelWidth = math.min(sceneWidth * 0.68, 278).toDouble();

    return Semantics(
      key: const ValueKey('poster_onboarding_jobs_scene'),
      label: i18n.posterOnboarding.sceneAccessibilityLabel,
      image: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            key: const ValueKey('poster_onboarding_job_scene'),
            width: sceneWidth,
            height: _jobSceneHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: 0,
                  right: 0,
                  top: _jobRowTop - PosterOnboardingJobCard.rotationOverflowPadding,
                  bottom: 0,
                  child: Motion.list(
                    key: const ValueKey('poster_onboarding_job_entrance_motion'),
                    effects: const [
                      FadeInMotionEffect(
                        duration: Duration(milliseconds: 1020),
                        curve: Curves.easeOut,
                        delay: Duration(milliseconds: 300),
                      ),
                      MoveMotionEffect(
                        begin: Offset(0, -_jobSceneHeight),
                        end: Offset.zero,
                        duration: Duration(milliseconds: 1000),
                        curve: Curves.easeOutCubic,
                        delay: Duration(milliseconds: 300),
                      ),
                    ],
                    child: Marquee(
                      key: const ValueKey('poster_onboarding_job_marquee'),
                      duration: const Duration(seconds: 30),
                      direction: MarqueeDirection.left,
                      spacing: 10,
                      children: [
                        PosterOnboardingJobCard.waiter(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.movingHelper(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.dogWalker(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.furnitureAssembler(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.storeAttendant(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.kitchenHelper(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.eventPhotographer(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.postConstructionCleaner(i18n: i18n, panelWidth: panelWidth),
                        PosterOnboardingJobCard.constructionHelper(i18n: i18n, panelWidth: panelWidth),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
