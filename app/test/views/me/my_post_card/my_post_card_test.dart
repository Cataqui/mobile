import 'package:cataqui_app/core/dtos/user_job.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:cataqui_app/views/me/widgets/post_status_dot.dart';
import 'package:cataqui_app/widgets/job_location_map/job_location_map.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../utils/test_app.dart';
import '../../../widgets/job_location_map/google_maps_test_renderer.dart';

void main() {
  late GoogleMapsTestRenderer mapRenderer;
  late Translations i18n;

  setUpAll(() => i18n = AppLocale.ptBr.buildSync());
  setUp(() => mapRenderer = GoogleMapsTestRenderer()..install());
  tearDown(() => mapRenderer.restore());

  testWidgets('when a post is active, it should show feed-style details and status over a full-card map', (
    tester,
  ) async {
    final job = UserJob.fixture().copyWith(
      jobId: 'active-job',
      title: 'Garçom',
      payment: r'R$100/dia',
      descriptionSummary: 'Preciso de um garçom para um evento.',
      status: JobStatus.active,
      createdAt: DateTime.utc(2026, 9, 23, 12),
    );

    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.pumpWidget(
        TestApp.screen(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 390, child: MyPostCard(job: job)),
          ),
        ),
      );
      await tester.pump();
    });

    expect(find.text('Garçom'), findsOneWidget);
    expect(find.text(r'R$100/dia'), findsOneWidget);
    expect(find.bySemanticsLabel(i18n.me.myPosts.activeStatus), findsOneWidget);
    expect(find.byType(MyPostStatusDot), findsOneWidget);
    final card = tester.getRect(find.byType(MyPostCard));
    final statusChip = tester.getRect(find.byType(MyPostStatusDot));
    expect(card.right - statusChip.right, 31);
    expect(statusChip.top - card.top, 31);
    expect(statusChip.top, lessThan(tester.getRect(find.text('Garçom')).top));
    expect(find.descendant(of: find.byType(MyPostCard), matching: find.byType(MateoSurface)), findsNWidgets(2));
    final surfaces = tester
        .widgetList<MateoSurface>(find.descendant(of: find.byType(MyPostCard), matching: find.byType(MateoSurface)))
        .toList();
    expect(surfaces.first.shape, const MateoShape.rounded(radius: 42));
    expect(surfaces.last.shape, const MateoShape.rounded(radius: 33));
    final map = tester.getRect(find.byType(JobLocationMap));
    expect(map.size, card.size);
    expect(tester.widget<JobLocationMap>(find.byType(JobLocationMap)).zoom, 13);
    expect(tester.widget<JobLocationMap>(find.byType(JobLocationMap)).offset, const Offset(0, 92));
    expect(card.height, closeTo(card.width * 1.25, 0.01));
    expect(mapRenderer.createdIds, isNotEmpty);

    await withClock(Clock.fixed(DateTime.utc(2026, 9, 24, 12)), () async {
      await tester.tap(find.byType(MyPostCard));
      await tester.pump();
    });
    expect(find.byType(MyPostCard), findsOneWidget);
  });

  testWidgets('when a post is archived, it should show the off-air status', (tester) async {
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          child: SizedBox(
            width: 390,
            child: MyPostCard(
              job: UserJob.fixture().copyWith(status: JobStatus.archived, createdAt: DateTime.utc(2026, 9, 23, 12)),
            ),
          ),
        ),
      ),
    );

    expect(find.bySemanticsLabel(i18n.me.myPosts.inactiveStatus), findsOneWidget);
    expect(find.byType(MyPostStatusDot), findsOneWidget);
  });

  testWidgets('when a post is loading, it should show a solid skeleton surface without creating a map', (tester) async {
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        const TestApp.screen(
          child: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 390, child: MyPostCard.skeleton()),
          ),
        ),
      ),
    );

    final card = find.byType(MyPostCard);
    final surface = tester.widget<MateoSurface>(find.descendant(of: card, matching: find.byType(MateoSurface)));
    final cardRect = tester.getRect(card);
    expect(cardRect.height, closeTo(cardRect.width * 1.25, 0.01));
    expect(surface.color, MateoTheme.of(tester.element(card)).palette.neutral[2]);
    expect(find.byType(Skeleton), findsOneWidget);
    expect(tester.widget<Skeleton>(find.byType(Skeleton)).transition, isA<SkeletonTransition>());
    expect(find.bySemanticsLabel(i18n.me.myPosts.loadingPostSemanticLabel), findsOneWidget);
    expect(find.byType(JobLocationMap), findsNothing);
    expect(mapRenderer.createdIds, isEmpty);
  });
}
