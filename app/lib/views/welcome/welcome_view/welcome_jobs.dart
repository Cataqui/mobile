part of 'welcome_view.dart';

abstract final class _WelcomeJobs {
  static List<_WelcomeJob> forTranslations(Translations i18n) {
    if (identical(_cachedTranslations, i18n)) return _cachedJobs;

    _cachedTranslations = i18n;
    return _cachedJobs = List.unmodifiable([
      _WelcomeJob(
        title: i18n.welcome.jobs.job1.title,
        amount: i18n.welcome.jobs.job1.amount,
        description: i18n.welcome.jobs.job1.description,
        postedTime: i18n.welcome.jobs.job1.postedTime,
        artwork: _WelcomeJobArtwork(
          top: _WelcomeJobIllustration(
            builder: $Illustrations.smallTruck,
            precache: $IllustrationsCache.precacheSmallTruck,
            backgroundColor: (palette) => palette.violet[7],
            illustrationColor: null,
            width: 48,
          ),
          right: _WelcomeJobIllustration(
            builder: $Illustrations.locationPinFront,
            precache: $IllustrationsCache.precacheLocationPinFront,
            backgroundColor: (palette) => palette.green[8],
            illustrationColor: null,
            width: 37,
            height: 37,
          ),
          bottom: _WelcomeJobIllustration(
            builder: $Illustrations.box,
            precache: $IllustrationsCache.precacheBox,
            backgroundColor: (palette) => palette.orange[8],
            illustrationColor: null,
            width: 37,
            height: 37,
          ),
          left: _WelcomeJobIllustration(
            builder: $Illustrations.toolBox,
            precache: $IllustrationsCache.precacheToolBox,
            backgroundColor: (palette) => palette.cyan[8],
            illustrationColor: null,
            width: 36,
            height: 36,
          ),
          corner: _WelcomeJobIllustration(
            builder: $Illustrations.ladder,
            precache: $IllustrationsCache.precacheLadder,
            backgroundColor: (palette) => palette.neutral[12],
            illustrationColor: null,
            width: 43,
          ),
        ),
      ),
      _WelcomeJob(
        title: i18n.welcome.jobs.job2.title,
        amount: i18n.welcome.jobs.job2.amount,
        description: i18n.welcome.jobs.job2.description,
        postedTime: i18n.welcome.jobs.job2.postedTime,
        artwork: _WelcomeJobArtwork(
          top: _WelcomeJobIllustration(
            builder: $Icons.pencil,
            precache: $IconsCache.precachePencil,
            backgroundColor: (palette) => palette.blue[7],
            illustrationColor: null,
            width: 30,
            height: 30,
          ),
          right: _WelcomeJobIllustration(
            builder: $Illustrations.notepad,
            precache: $IllustrationsCache.precacheNotepad,
            backgroundColor: (palette) => palette.orange[8],
            illustrationColor: null,
            width: 42,
            height: 42,
          ),
          left: _WelcomeJobIllustration(
            builder: $Illustrations.bowTie,
            precache: $IllustrationsCache.precacheBowTie,
            backgroundColor: (palette) => palette.teal[7],
            illustrationColor: null,
            width: 36,
          ),
          bottom: _WelcomeJobIllustration(
            builder: $Illustrations.cloche,
            precache: $IllustrationsCache.precacheCloche,
            backgroundColor: (palette) => palette.green[8],
            illustrationColor: null,
            width: 42,
            height: 42,
          ),
          corner: _WelcomeJobIllustration(
            builder: $Illustrations.ceramicPlate,
            precache: $IllustrationsCache.precacheCeramicPlate,
            backgroundColor: (palette) => palette.neutral[12],
            illustrationColor: null,
            width: 43,
          ),
        ),
      ),
      _WelcomeJob(
        title: i18n.welcome.jobs.job3.title,
        amount: i18n.welcome.jobs.job3.amount,
        description: i18n.welcome.jobs.job3.description,
        postedTime: i18n.welcome.jobs.job3.postedTime,
        artwork: _WelcomeJobArtwork(
          top: _WelcomeJobIllustration(
            builder: $Illustrations.floorMop,
            precache: $IllustrationsCache.precacheFloorMop,
            backgroundColor: (palette) => palette.green[7],
            illustrationColor: null,
            width: 42,
            height: 42,
          ),
          right: _WelcomeJobIllustration(
            builder: $Illustrations.vacuumCleaner,
            precache: $IllustrationsCache.precacheVacuumCleaner,
            backgroundColor: (palette) => palette.violet[6],
            illustrationColor: null,
            width: 42,
            height: 42,
          ),
          bottom: _WelcomeJobIllustration(
            builder: $Illustrations.sprayBottle,
            precache: $IllustrationsCache.precacheSprayBottle,
            backgroundColor: (palette) => palette.neutral[12],
            illustrationColor: null,
            width: 42,
          ),
          left: _WelcomeJobIllustration(
            builder: $Illustrations.rubberGloves,
            precache: $IllustrationsCache.precacheRubberGloves,
            backgroundColor: (palette) => palette.amber[7],
            illustrationColor: null,
            width: 38,
            height: 38,
          ),
          corner: _WelcomeJobIllustration(
            builder: $Illustrations.foldedCloth,
            precache: $IllustrationsCache.precacheFoldedCloth,
            backgroundColor: (palette) => palette.orange[7],
            illustrationColor: null,
            width: 48,
          ),
        ),
      ),
      _WelcomeJob(
        title: i18n.welcome.jobs.job4.title,
        amount: i18n.welcome.jobs.job4.amount,
        description: i18n.welcome.jobs.job4.description,
        postedTime: i18n.welcome.jobs.job4.postedTime,
        artwork: _WelcomeJobArtwork(
          top: _WelcomeJobIllustration(
            builder: $Illustrations.wheelbarrow,
            precache: $IllustrationsCache.precacheWheelbarrow,
            backgroundColor: (palette) => palette.cyan[6],
            illustrationColor: null,
            width: 48,
            height: 48,
          ),
          right: _WelcomeJobIllustration(
            builder: $Illustrations.constructionHat,
            precache: $IllustrationsCache.precacheConstructionHat,
            backgroundColor: (palette) => palette.green[8],
            illustrationColor: null,
            width: 48,
          ),
          left: _WelcomeJobIllustration(
            builder: $Illustrations.ladder,
            precache: $IllustrationsCache.precacheLadder,
            backgroundColor: (palette) => palette.neutral[12],
            illustrationColor: null,
            width: 43,
          ),
          bottom: _WelcomeJobIllustration(
            builder: $Illustrations.cementBag,
            precache: $IllustrationsCache.precacheCementBag,
            backgroundColor: (palette) => palette.blue[8],
            illustrationColor: null,
            width: 58,
          ),
          corner: _WelcomeJobIllustration(
            builder: $Illustrations.shovel,
            precache: $IllustrationsCache.precacheShovel,
            backgroundColor: (palette) => palette.neutral[2],
            illustrationColor: null,
            width: 36,
            height: 36,
          ),
        ),
      ),
      _WelcomeJob(
        title: i18n.welcome.jobs.job5.title,
        amount: i18n.welcome.jobs.job5.amount,
        description: i18n.welcome.jobs.job5.description,
        postedTime: i18n.welcome.jobs.job5.postedTime,
        artwork: _WelcomeJobArtwork(
          top: _WelcomeJobIllustration(
            builder: $Illustrations.greenFoldedMicrofiberCloth,
            precache: $IllustrationsCache.precacheGreenFoldedMicrofiberCloth,
            backgroundColor: (palette) => palette.yellow[7],
            illustrationColor: null,
            width: 40,
            height: 40,
          ),
          right: _WelcomeJobIllustration(
            builder: $Illustrations.tireBrush,
            precache: $IllustrationsCache.precacheTireBrush,
            backgroundColor: (palette) => palette.green[8],
            illustrationColor: null,
            width: 46,
          ),
          left: _WelcomeJobIllustration(
            builder: $Illustrations.hose,
            precache: $IllustrationsCache.precacheHose,
            backgroundColor: (palette) => palette.orange[7],
            illustrationColor: null,
            width: 42,
          ),
          bottom: _WelcomeJobIllustration(
            builder: $Illustrations.highPressureWasher,
            precache: $IllustrationsCache.precacheHighPressureWasher,
            backgroundColor: (palette) => palette.cyan[8],
            illustrationColor: null,
            width: 40,
            height: 40,
          ),
          corner: _WelcomeJobIllustration(
            builder: $Illustrations.carWashBucket,
            precache: $IllustrationsCache.precacheCarWashBucket,
            backgroundColor: (palette) => palette.pink[7],
            illustrationColor: null,
            width: 43,
          ),
        ),
      ),
    ]);
  }

  static Translations? _cachedTranslations;
  static List<_WelcomeJob> _cachedJobs = const [];
}
