import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _fixedClock = Clock(() => DateTime(2025, 6, 15, 20));

void main() {
  group('FeedJobCard Golden Tests', () {
    goldenTest(
      'when rendering the resting state, it should match the approved golden',
      fileName: 'feed_job_card_resting',
      builder: () => withClock(
        _fixedClock,
        () => ProviderScope(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(feedJob: FeedJobDto.fixture(), onTap: () async {}),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering a long title, it should clamp to 2 lines with ellipsis',
      fileName: 'feed_job_card_long_title',
      builder: () => withClock(
        _fixedClock,
        () => ProviderScope(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(
              feedJob: FeedJobDto.fixture().copyWith(
                title: 'Preciso de um ajudante muito experiente para descarregar caminhão pesado amanhã cedo',
              ),
              onTap: () async {},
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering a long description, it should clamp to 3 lines with ellipsis',
      fileName: 'feed_job_card_long_description',
      builder: () => withClock(
        _fixedClock,
        () => ProviderScope(
          child: SizedBox(
            width: 360,
            child: FeedJobCard(
              feedJob: FeedJobDto.fixture().copyWith(
                descriptionSummary: 'Preciso de um ajudante muito experiente para descarregar caminhão pesado amanhã cedo. Precisa ter força e disposição. O pagamento é por dia e o trabalho é pesado.',
              ),
              onTap: () async {},
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering expanded full width, it should match the approved golden',
      fileName: 'feed_job_card_expanded_full_width',
      builder: () => withClock(
        _fixedClock,
        () => ProviderScope(
          child: SizedBox(
            width: 360,
            child: Align(
              alignment: Alignment.topCenter,
              child: FeedJobCard(feedJob: FeedJobDto.fixture(), onTap: () async {}),
            ),
          ),
        ),
      ),
    );

    goldenTest(
      'when rendering expanded minimal content, it should match the approved golden',
      fileName: 'feed_job_card_expanded_minimal_content',
      builder: () => withClock(
        _fixedClock,
        () => ProviderScope(
          child: SizedBox(
            width: 360,
            child: Align(
              alignment: Alignment.topCenter,
              child: FeedJobCard(
                feedJob: FeedJobDto.fixture().copyWith(
                  title: 'Ajudante',
                  descriptionSummary: 'Rápido.',
                ),
                onTap: () async {},
              ),
            ),
          ),
        ),
      ),
    );
  });
}
