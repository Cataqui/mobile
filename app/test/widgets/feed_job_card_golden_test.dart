import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/widgets/feed_job_card/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../utils/test_app.dart';

final _fixedClock = Clock(() => DateTime(2025, 6, 15, 20));

void main() {
  group('FeedJobCard Golden Tests', () {
    goldenTest(
      'when rendering the resting state, it should match the approved golden',
      fileName: 'feed_job_card_resting',
      pumpWidget: TestApp.pumpGolden,
      constraints: const BoxConstraints.tightFor(width: 360, height: 300),
      pumpBeforeTest: TestApp.settleGolden,
      builder: () => withClock(
        _fixedClock,
        () => TestApp.screen(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(feedJob: FeedJobDto.fixture().copyWith(createdAt: DateTime(2025, 6, 15, 17))),
          ),
        ),
      ),
    );

    goldenTest(
      'when payment is null, it should show A Combinar',
      fileName: 'feed_job_card_null_payment',
      pumpWidget: TestApp.pumpGolden,
      constraints: const BoxConstraints.tightFor(width: 360, height: 300),
      pumpBeforeTest: TestApp.settleGolden,
      builder: () => withClock(
        _fixedClock,
        () => TestApp.screen(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(
              feedJob: FeedJobDto.fixture().copyWith(createdAt: DateTime(2025, 6, 15, 17), payment: null),
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering a long title, it should clamp to 2 lines with ellipsis',
      fileName: 'feed_job_card_long_title',
      pumpWidget: TestApp.pumpGolden,
      constraints: const BoxConstraints.tightFor(width: 360, height: 300),
      pumpBeforeTest: TestApp.settleGolden,
      builder: () => withClock(
        _fixedClock,
        () => TestApp.screen(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(
              feedJob: FeedJobDto.fixture()
                  .copyWith(createdAt: DateTime(2025, 6, 15, 17))
                  .copyWith(
                    title: 'Preciso de um ajudante muito experiente para descarregar caminhão pesado amanhã cedo',
                  ),
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering a long description, it should clamp to 3 lines with ellipsis',
      fileName: 'feed_job_card_long_description',
      pumpWidget: TestApp.pumpGolden,
      constraints: const BoxConstraints.tightFor(width: 360, height: 300),
      pumpBeforeTest: TestApp.settleGolden,
      builder: () => withClock(
        _fixedClock,
        () => TestApp.screen(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(
              feedJob: FeedJobDto.fixture()
                  .copyWith(createdAt: DateTime(2025, 6, 15, 17))
                  .copyWith(
                    descriptionSummary:
                        'Preciso de um ajudante muito experiente para descarregar caminhão pesado amanhã cedo. Precisa ter força e disposição. O pagamento é por dia e o trabalho é pesado.',
                  ),
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering expanded full width, it should match the approved golden',
      fileName: 'feed_job_card_expanded_full_width',
      pumpWidget: TestApp.pumpGolden,
      constraints: const BoxConstraints.tightFor(width: 360, height: 300),
      pumpBeforeTest: TestApp.settleGolden,
      builder: () => withClock(
        _fixedClock,
        () => TestApp.screen(
          child: SizedBox(
            width: 360,
            child: Align(
              alignment: Alignment.topCenter,
              child: FeedJobCard(feedJob: FeedJobDto.fixture().copyWith(createdAt: DateTime(2025, 6, 15, 17))),
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering expanded minimal content, it should match the approved golden',
      fileName: 'feed_job_card_expanded_minimal_content',
      pumpWidget: TestApp.pumpGolden,
      constraints: const BoxConstraints.tightFor(width: 360, height: 300),
      pumpBeforeTest: TestApp.settleGolden,
      builder: () => withClock(
        _fixedClock,
        () => TestApp.screen(
          child: SizedBox(
            width: 360,
            child: Align(
              alignment: Alignment.topCenter,
              child: FeedJobCard(
                feedJob: FeedJobDto.fixture()
                    .copyWith(createdAt: DateTime(2025, 6, 15, 17))
                    .copyWith(title: 'Ajudante', descriptionSummary: 'Rápido.'),
              ),
            ),
          ),
        ),
      ),
    );
  });
}
