import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/widgets/feed_job_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedJobCard Golden Tests', () {
    goldenTest(
      'when rendering visual states, it should match the approved goldens',
      fileName: 'feed_job_card_states',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 360),
        children: [
          GoldenTestScenario(
            name: 'resting',
            child: ProviderScope(
              child: SizedBox(
                width: 360,
                child: FeedJobCard(feedJob: FeedJobDto.fixture(), onTap: () async {}),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'long title',
            child: ProviderScope(
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
          GoldenTestScenario(
            name: 'expanded full width',
            child: ProviderScope(
              child: SizedBox(
                width: 360,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: FeedJobCard(feedJob: FeedJobDto.fixture(), onTap: () async {}),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'expanded minimal content',
            child: ProviderScope(
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
        ],
      ),
    );
  });
}
