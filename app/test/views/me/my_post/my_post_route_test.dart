import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_detail_chips.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/my_post/my_post_morph_curve.dart';
import 'package:cataqui_app/views/me/my_post/my_post_morph_target.dart';
import 'package:cataqui_app/views/me/my_post/my_post_route.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:cataqui_app/views/me/my_post/my_post_view.dart';
import 'package:cataqui_app/views/me/my_post_card/my_post_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../utils/test_app.dart';
import '../../../widgets/job_location_map/google_maps_test_renderer.dart';
import '../fake_app_auth_state.dart';
import 'fake_my_post_state.dart';

void main() {
  testWidgets('title reflows and payment follows at intermediate flight widths', (tester) async {
    final summary = UserJobSummaryDto.fixture().copyWith(title: 'Mercado Pago');

    Future<({int titleLines, double paymentTop})> layoutAtWidth(double width) async {
      await tester.pumpWidget(
        TestApp(
          child: SizedBox(
            width: width,
            height: 160,
            child: MyPostHeaderSurface(summary: summary, timeAgo: '1 dia atrás', payment: r'R$100/dia', expansion: .5),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final titleBottom = tester.getBottomLeft(find.text(summary.title)).dy;
      final paymentTop = tester.getTopLeft(find.text(r'R$100/dia')).dy;
      expect(paymentTop, greaterThanOrEqualTo(titleBottom));
      final titleLines = tester
          .renderObject<RenderParagraph>(find.text(summary.title))
          .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: summary.title.length))
          .map((box) => box.top)
          .toSet()
          .length;
      return (titleLines: titleLines, paymentTop: paymentTop);
    }

    final wrapped = await layoutAtWidth(290);
    final unwrapped = await layoutAtWidth(350);
    expect(wrapped.titleLines, 2);
    expect(unwrapped.titleLines, 1);
    expect(wrapped.paymentTop, greaterThan(unwrapped.paymentTop));
  });

  testWidgets('tapping a Me card morphs into My Post and close returns to the card', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final mapRenderer = GoogleMapsTestRenderer()..install();
    addTearDown(mapRenderer.restore);
    final summary = UserJobSummaryDto.fixture().copyWith(
      jobId: 'my-post-route-job',
      title: 'Mercado Pago',
      descriptionSummary:
          'Preciso de ajuda para organizar o estoque e preparar as entregas de hoje no centro da cidade.',
    );
    late FakeMyPostState fakeState;
    final router = GoRouter(
      observers: [MateoNavigatorObserver()],
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Material(
            child: Center(
              child: SizedBox(width: 320, child: MyPostCard(job: summary)),
            ),
          ),
        ),
        $myPostRoute,
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: router,
        providerOverrides: [
          goRouterProvider.overrideWithValue(router),
          appAuthStateProvider.overrideWith(
            () => FakeAppAuthState(AuthSessionDto.fixture().copyWith(accessTokenExpiresAt: DateTime.utc(2100))),
          ),
          myPostStateProvider(
            summary.jobId,
          ).overrideWith(() => fakeState = FakeMyPostState(const AsyncLoading<UserJobDto>())),
        ],
      ),
    );
    await tester.pump();
    expect(
      tester
          .renderObject<RenderParagraph>(find.text(summary.title))
          .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: summary.title.length))
          .map((box) => box.top)
          .toSet()
          .length,
      2,
    );
    final container = ProviderScope.containerOf(tester.element(find.byType(MyPostCard)));
    final target = container.read(myPostMorphTargetProvider(summary.jobId));
    expect(target.curve, isA<MyPostMorphCurve>());
    expect(target.reverseCurve, isA<MyPostMorphCurve>());

    void expectFlightTextSeparated() {
      final flight = find.byWidgetPredicate(
        (widget) => widget is MyPostHeaderSurface && widget.expansion > 0 && widget.expansion < 1,
      );
      if (flight.evaluate().isEmpty) return;
      final title = find.descendant(of: flight, matching: find.text(summary.title));
      final payment = find.descendant(of: flight, matching: find.text(summary.payment!));
      expect(tester.getTopLeft(payment).dy, greaterThanOrEqualTo(tester.getBottomLeft(title).dy));
    }

    await tester.tap(find.byType(MyPostCard));
    await tester.pump();
    await tester.pump();
    for (var frame = 0; frame < 9; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'opening frame $frame');
      expectFlightTextSeparated();
      if (frame == 5) {
        fakeState.complete(UserJobDto.fixture());
        expect(find.byType(MorphNode), findsOneWidget);
        expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphNodePaint'), findsOneWidget);
        final viewFade = tester.widget<FadeTransition>(
          find.ancestor(of: find.byKey(const ValueKey('my_post_view')), matching: find.byType(FadeTransition)).first,
        );
        expect(viewFade.opacity.value, inExclusiveRange(0, 1));
        final projectedFade = tester.widget<FadeTransition>(
          find
              .ancestor(
                of: find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphNodePaint'),
                matching: find.byType(FadeTransition),
              )
              .first,
        );
        expect(projectedFade.opacity.value, viewFade.opacity.value);
      }
    }
    expect(find.byType(MyPostView), findsOneWidget);
    expect(target.status.value, MorphTagStatus.flying);
    final node = find.byType(MorphNode);
    expect(node, findsOneWidget);
    expect(find.descendant(of: node, matching: find.byKey(const ValueKey('my_post_card_fade'))), findsOneWidget);
    expect(find.descendant(of: node, matching: find.byType(MyPostDetailChips)), findsOneWidget);
    final flight = find.byWidgetPredicate(
      (widget) => widget is MyPostHeaderSurface && widget.expansion > 0 && widget.expansion < 1,
    );
    expect(flight, findsOneWidget);
    expect(find.descendant(of: flight, matching: find.byKey(const ValueKey('my_post_card_fade'))), findsNothing);
    final flightSurface = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: flight,
            matching: find.byWidgetPredicate(
              (widget) => widget is DecoratedBox && widget.decoration is ShapeDecoration,
            ),
          )
          .first,
    );
    expect((flightSurface.decoration as ShapeDecoration).shadows, isNotEmpty);
    for (var frame = 0; frame < 25; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'landing frame $frame');
      expectFlightTextSeparated();
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(target.status.value, MorphTagStatus.completed);
    expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphNodePaint'), findsNothing);
    final coveredCard = find.byType(MyPostCard, skipOffstage: false);
    expect(coveredCard, findsOneWidget);
    expect(TickerMode.valuesOf(tester.element(coveredCard)).enabled, isFalse);
    expect(ModalRoute.of(tester.element(find.byType(MyPostView)))!.opaque, isTrue);
    expect(
      tester
          .renderObject<RenderParagraph>(
            find.descendant(of: find.byType(MyPostView), matching: find.text(summary.title)),
          )
          .getBoxesForSelection(TextSelection(baseOffset: 0, extentOffset: summary.title.length))
          .map((box) => box.top)
          .toSet()
          .length,
      1,
    );
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('my_post_close_button')));
    await tester.pump();
    expect(router.state.matchedLocation, '/');
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      if (frame == 2) {
        expect(find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphNodePaint'), findsOneWidget);
        final viewFade = tester.widget<FadeTransition>(
          find.ancestor(of: find.byKey(const ValueKey('my_post_view')), matching: find.byType(FadeTransition)).first,
        );
        expect(viewFade.opacity.value, inExclusiveRange(0, 1));
      }
      expect(tester.takeException(), isNull, reason: 'returning frame $frame');
      expectFlightTextSeparated();
    }
    await tester.pump();
    for (var frame = 0; frame < 6; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull, reason: 'reveal frame $frame');
      expectFlightTextSeparated();
    }
    expect(tester.takeException(), isNull);
    final returningHeader = tester.widget<MyPostHeaderSurface>(
      find.byWidgetPredicate((widget) => widget is MyPostHeaderSurface && widget.expansion > 0 && widget.expansion < 1),
    );
    expect(returningHeader.description, summary.descriptionSummary);
    expect(returningHeader.descriptionOpacity, greaterThan(.15));
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);
    final nearlyLandedHeader = tester.widget<MyPostHeaderSurface>(
      find.byWidgetPredicate((widget) => widget is MyPostHeaderSurface && widget.expansion > 0 && widget.expansion < 1),
    );
    expect(nearlyLandedHeader.descriptionOpacity, greaterThan(.95));
    for (var frame = 0; frame < 10; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.byType(MyPostView), findsNothing);
    expect(find.byType(MyPostCard), findsOneWidget);
    expect(find.text(summary.descriptionSummary), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
