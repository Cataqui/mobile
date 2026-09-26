import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/views/me/my_post/my_post_route.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:cataqui_app/views/me/my_post/my_post_view.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:clock/clock.dart';
import 'package:flutter/foundation.dart' show AsyncCallback;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../../utils/test_app.dart';
import '../../../widgets/job_location_map/google_maps_test_renderer.dart';
import 'fake_my_post_state.dart';

void main() {
  setUp(() {
    final mapRenderer = GoogleMapsTestRenderer()..install();
    addTearDown(mapRenderer.restore);
  });

  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'active My Post loaded',
        fileName: 'my_post_active_loaded',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MyPostGoldenTestHelpers.pumpWidget,
        pumpBeforeTest: MyPostGoldenTestHelpers.pumpFrame,
        builder: MyPostGoldenTestHelpers.direct,
      );

      goldenTest(
        'archived My Post loaded',
        fileName: 'my_post_archived_loaded',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MyPostGoldenTestHelpers.pumpWidget,
        pumpBeforeTest: MyPostGoldenTestHelpers.pumpFrame,
        builder: () => MyPostGoldenTestHelpers.direct(archived: true),
      );

      goldenTest(
        'My Post loading detail',
        fileName: 'my_post_loading',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MyPostGoldenTestHelpers.pumpWidget,
        pumpBeforeTest: MyPostGoldenTestHelpers.pumpFrame,
        builder: () => MyPostGoldenTestHelpers.direct(loading: true),
      );

      goldenTest(
        'My Post detail error',
        fileName: 'my_post_error',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MyPostGoldenTestHelpers.pumpWidget,
        pumpBeforeTest: MyPostGoldenTestHelpers.pumpFrame,
        builder: () => MyPostGoldenTestHelpers.direct(error: true),
      );

      goldenTest(
        'My Post card midway through opening flight',
        fileName: 'my_post_morph_midpoint',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        pumpWidget: MyPostGoldenTestHelpers.pumpWidget,
        pumpBeforeTest: MyPostGoldenTestHelpers.pumpFrame,
        whilePerforming: MyPostGoldenTestHelpers.openToMidpoint,
        builder: MyPostGoldenTestHelpers.routed,
      );
    },
  );
}

class MyPostGoldenTestHelpers {
  MyPostGoldenTestHelpers._();

  static final _fixedClock = Clock.fixed(DateTime.utc(2026, 9, 24, 12));
  static final _summary = UserJobSummaryDto.fixture().copyWith(
    title: 'Garçom',
    payment: r'R$100/dia',
    createdAt: DateTime.utc(2026, 9, 23, 12),
  );
  static final _detail = UserJobDto.fixture().copyWith(
    contact: UserJobDto.fixture().contact?.copyWith(identifier: '+5511969230546'),
    location: UserJobDto.fixture().location.copyWith(title: 'Rua Oridinuva 32'),
    description:
        'Preciso de um garçom para um evento no sábado à noite. O trabalho inclui atender os convidados, servir bebidas, repor a mesa e ajudar na organização do espaço durante toda a festa. O evento será na região da Vila Mariana e começa às 18h. Procuro alguém com experiência, pontualidade e disponibilidade até o encerramento. Entre em contato para combinar os detalhes e o pagamento.',
  );

  static Widget direct({bool archived = false, bool loading = false, bool error = false}) {
    final summary = archived ? _summary.copyWith(status: .archived) : _summary;
    final detail = archived ? _detail.copyWith(status: .archived, contact: null) : _detail;
    final value = loading
        ? const AsyncLoading<UserJobDto>()
        : error
        ? AsyncError<UserJobDto>(StateError('offline'), StackTrace.empty)
        : AsyncData<UserJobDto>(detail);
    return TestApp.screen(
      mediaQueryData: const MediaQueryData(
        size: Size(390, 844),
        padding: EdgeInsets.only(top: 59, bottom: 24),
        disableAnimations: true,
      ),
      providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(value))],
      child: MyPostView(summary: summary),
    );
  }

  static Widget routed() {
    final router = GoRouter(
      observers: [MateoNavigatorObserver()],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Material(
            child: Center(
              child: SizedBox(width: 340, child: MyPostCard(job: _summary)),
            ),
          ),
        ),
        $myPostRoute,
      ],
    );
    return TestApp.router(
      routerConfig: router,
      mediaQueryData: const MediaQueryData(size: Size(390, 844), padding: EdgeInsets.only(top: 59, bottom: 24)),
      providerOverrides: [myPostStateProvider(_summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(_detail)))],
    );
  }

  static Future<void> pumpWidget(WidgetTester tester, Widget widget) =>
      withClock(_fixedClock, () => tester.pumpWidget(widget));

  static Future<void> pumpFrame(WidgetTester tester) => withClock(_fixedClock, tester.pump);

  static Future<AsyncCallback?> openToMidpoint(WidgetTester tester) async {
    return withClock(_fixedClock, () async {
      unawaited(
        MyPostRoute(jobId: _summary.jobId, $extra: _summary).push<void>(tester.element(find.byType(MyPostCard))),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 90));
      return null;
    });
  }
}
