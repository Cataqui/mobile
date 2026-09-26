import 'dart:ui' as ui;

import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/me/my_post/my_post_detail_chips.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:cataqui_app/views/me/my_post/my_post_view.dart';
import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../utils/test_app.dart';
import 'fake_my_post_state.dart';

void main() {
  late Translations i18n;
  setUpAll(() => i18n = AppLocale.ptBr.buildSync());

  testWidgets('loaded active post shows the full detail and read-only chips', (tester) async {
    final summary = UserJobSummaryDto.fixture().copyWith(title: 'Garçom', payment: r'R$100/dia');
    final detail = UserJobDto.fixture().copyWith(description: 'Trabalho para o sábado à noite.');
    await withClock(
      Clock.fixed(DateTime.utc(2026, 9, 24, 12)),
      () => tester.pumpWidget(
        TestApp.screen(
          providerOverrides: [
            myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail))),
          ],
          child: MyPostView(summary: summary),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(MyPostHeaderSurface), findsOneWidget);
    expect(find.text('Garçom'), findsOneWidget);
    expect(find.text(r'R$100/dia'), findsOneWidget);
    expect(find.text(detail.description), findsOneWidget);
    expect(find.text(detail.location.title), findsOneWidget);
    expect(find.byType(MyPostDetailChips), findsOneWidget);
    expect(find.bySemanticsLabel(i18n.me.myPosts.activeStatus), findsOneWidget);
    expect(tester.widgetList<Skeleton>(find.byType(Skeleton)).every((skeleton) => !skeleton.enabled), isTrue);
    expect(tester.widgetList<MateoButton>(find.byType(MateoButton)).length, 1);
    expect(find.byType(MateoView), findsOneWidget);
    expect(find.byKey(const ValueKey('my_post_backdrop')), findsNothing);
    final background = tester.widget<MateoViewSurface>(find.byType(MateoViewSurface));
    final theme = MateoTheme.of(tester.element(find.byType(MyPostView)));
    expect(background.color, theme.colorScheme.background);
  });

  testWidgets('loading post retains the summary and placeholder chips', (tester) async {
    final summary = UserJobSummaryDto.fixture();
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(const AsyncLoading<UserJobDto>())),
        ],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();
    expect(find.text(summary.title), findsOneWidget);
    expect(find.bySemanticsLabel(i18n.me.myPost.loadingSemanticLabel), findsOneWidget);
    expect(tester.widgetList<Skeleton>(find.byType(Skeleton)).where((skeleton) => skeleton.enabled).length, 1);
    expect(find.descendant(of: find.byType(MyPostDetailChips), matching: find.byType(Skeleton)), findsNothing);
    expect(find.byKey(const ValueKey(#contact)), findsOneWidget);
    expect(find.byKey(const ValueKey(#location)), findsOneWidget);
    expect(find.descendant(of: find.byType(MyPostDetailChips), matching: find.byType(Morph)), findsNothing);
    expect(find.text(i18n.me.myPost.unknown), findsNWidgets(2));
  });

  testWidgets('chips resize without disappearing or overflowing when detail loads', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = UserJobSummaryDto.fixture();
    final fixture = UserJobDto.fixture();
    final detail = fixture.copyWith(location: fixture.location.copyWith(title: 'Rua Oridinuva 32, Vila Mariana' * 8));
    late FakeMyPostState fakeState;
    await tester.pumpWidget(
      RepaintBoundary(
        key: const ValueKey('chip_continuity_capture'),
        child: TestApp.screen(
          providerOverrides: [
            myPostStateProvider(
              summary.jobId,
            ).overrideWith(() => fakeState = FakeMyPostState(const AsyncLoading<UserJobDto>())),
          ],
          child: MyPostView(summary: summary),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final contactState = tester.state(find.byKey(const ValueKey(#contact)));
    final locationState = tester.state(find.byKey(const ValueKey(#location)));
    final loadingLocationWidth = tester.getSize(find.byKey(const ValueKey(#location))).width;
    final contactRect = tester.getRect(find.byKey(const ValueKey(#contact)));
    final samplePoint = Offset(contactRect.left + 6, contactRect.center.dy);
    final background = MateoTheme.of(tester.element(find.byType(MyPostDetailChips))).colorScheme.background;
    Future<List<int>> pixelAt(Offset point) async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('chip_continuity_capture')),
      );
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = (await tester.runAsync(() => image.toByteData(format: ui.ImageByteFormat.rawRgba)))!;
      final offset = ((point.dy.floor() * image.width) + point.dx.floor()) * 4;
      final pixel = [for (var channel = 0; channel < 3; channel++) bytes.getUint8(offset + channel)];
      image.dispose();
      return pixel;
    }

    Future<void> expectChipPainted(int frame) async {
      final pixel = await pixelAt(samplePoint);
      expect(
        pixel,
        isNot([background.r, background.g, background.b].map((channel) => (channel * 255).round()).toList()),
        reason: 'the contact chip disappeared at frame $frame',
      );
    }

    await expectChipPainted(-1);
    fakeState.complete(detail);
    await tester.pump();
    await expectChipPainted(0);
    for (var frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      await expectChipPainted(frame);
      if (frame == 4) {
        final capsule = tester.getRect(find.byKey(const ValueKey(#contact)));
        final corner = await pixelAt(Offset(capsule.right - 2, capsule.top + 2));
        final outside = await pixelAt(Offset(capsule.right + 2, capsule.top + 2));
        expect(corner, outside, reason: 'the capsule must keep its rounded end while resizing');
      }
      expect(tester.takeException(), isNull, reason: 'resize frame $frame overflowed');
    }
    expect(tester.state(find.byKey(const ValueKey(#contact))), same(contactState));
    expect(tester.state(find.byKey(const ValueKey(#location))), same(locationState));
    expect(tester.getSize(find.byKey(const ValueKey(#location))).width, greaterThan(loadingLocationWidth));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(find.text(detail.location.title), findsWidgets);
    expect(
      find.descendant(of: find.byKey(const ValueKey(#contact)), matching: find.textContaining('+55')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty contact and location values show the localized unknown label', (tester) async {
    final summary = UserJobSummaryDto.fixture();
    final fixture = UserJobDto.fixture();
    final detail = fixture.copyWith(
      contact: fixture.contact!.copyWith(identifier: '  '),
      location: fixture.location.copyWith(title: '  '),
    );
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();

    expect(find.text(i18n.me.myPost.unknown), findsNWidgets(2));
    final chipIcons = tester.widgetList<MateoIcon>(
      find.descendant(of: find.byType(MyPostDetailChips), matching: find.byType(MateoIcon)),
    );
    expect(chipIcons.map((icon) => icon.icon), contains(MateoIconData.questionmark));
    expect(chipIcons.map((icon) => icon.icon), isNot(contains(MateoIconData.whatsapp)));
  });

  testWidgets('archived post uses the background color and omits absent contact', (tester) async {
    final summary = UserJobSummaryDto.fixture().copyWith(status: JobStatus.archived);
    final detail = UserJobDto.fixture().copyWith(contact: null, status: JobStatus.archived);
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();
    expect(find.bySemanticsLabel(i18n.me.myPosts.inactiveStatus), findsOneWidget);
    expect(find.text(detail.location.title), findsOneWidget);
    expect(find.textContaining('+55'), findsNothing);
    expect(find.byKey(const ValueKey('my_post_backdrop')), findsNothing);
    final background = tester.widget<MateoViewSurface>(find.byType(MateoViewSurface));
    final theme = MateoTheme.of(tester.element(find.byType(MyPostView)));
    expect(background.color, theme.colorScheme.background);
  });

  testWidgets('long chip values remain complete and scroll horizontally', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = UserJobSummaryDto.fixture();
    const locationTitle = 'Rua Oridinuva 32, Vila Mariana, São Paulo';
    final detail = UserJobDto.fixture().copyWith(
      location: UserJobDto.fixture().location.copyWith(title: locationTitle),
    );
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();

    final chips = find.byType(MyPostDetailChips);
    final horizontalScroll = find.descendant(of: chips, matching: find.byType(SingleChildScrollView));
    expect(horizontalScroll, findsOneWidget);
    expect(tester.widget<SingleChildScrollView>(horizontalScroll).scrollDirection, Axis.horizontal);
    expect(tester.getRect(horizontalScroll).left, 0);
    expect(tester.getRect(horizontalScroll).width, 390);
    expect(tester.getTopLeft(find.byKey(const ValueKey(#contact))).dx, 24);
    final locationText = find.text(locationTitle);
    expect(tester.widget<Text>(locationText).overflow, isNot(TextOverflow.ellipsis));
    final before = tester.getTopLeft(locationText).dx;
    await tester.drag(horizontalScroll, const Offset(-220, 0));
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.getTopLeft(locationText).dx, lessThan(before));
  });

  testWidgets('chips and description start below the card fade', (tester) async {
    final summary = UserJobSummaryDto.fixture().copyWith(title: 'Garçom', payment: r'R$100/dia');
    final detail = UserJobDto.fixture().copyWith(description: 'Trabalho para sábado.');
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();

    final fade = tester.getRect(find.byKey(const ValueKey('my_post_card_fade')));
    final chipsTop = tester.getTopLeft(find.byType(MyPostDetailChips)).dy;
    final paymentBottom = tester.getBottomLeft(find.text(r'R$100/dia')).dy;
    final cardBottom = tester.getBottomLeft(find.byKey(const ValueKey('my_post_header_card'))).dy;
    final descriptionTop = tester.getTopLeft(find.byKey(const ValueKey('my_post_description'))).dy;
    expect(cardBottom - paymentBottom, greaterThanOrEqualTo(60));
    expect(fade.top - paymentBottom, greaterThanOrEqualTo(8));
    expect(chipsTop - paymentBottom, inInclusiveRange(42, 50));
    expect(descriptionTop, greaterThan(chipsTop));
  });

  testWidgets('detail status replaces a stale active summary', (tester) async {
    final summary = UserJobSummaryDto.fixture();
    final detail = UserJobDto.fixture().copyWith(status: JobStatus.archived);
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel(i18n.me.myPosts.inactiveStatus), findsOneWidget);
  });

  testWidgets('detail failure keeps the summary and retry loads the content', (tester) async {
    final summary = UserJobSummaryDto.fixture();
    final detail = UserJobDto.fixture().copyWith(description: 'Descrição depois de tentar de novo.');
    late FakeMyPostState fakeState;
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          myPostStateProvider(summary.jobId).overrideWith(
            () => fakeState = FakeMyPostState(AsyncError(Exception('offline'), StackTrace.empty), retryValue: detail),
          ),
        ],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();
    expect(find.text(summary.title), findsOneWidget);
    expect(find.text(i18n.me.myPost.error.title), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('my_post_retry_button')));
    await tester.pump();
    await tester.pump();
    expect(fakeState.retryCalls, 1);
    expect(find.text(detail.description), findsOneWidget);
  });

  testWidgets('long detail scrolls while the close control stays fixed', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = UserJobSummaryDto.fixture();
    final detail = UserJobDto.fixture().copyWith(description: List.filled(35, 'Detalhes do trabalho.').join(' '));
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();
    final closeTop = tester.getTopLeft(find.byKey(const ValueKey('my_post_close_button'))).dy;
    final cardTop = tester.getTopLeft(find.byType(MyPostHeaderSurface)).dy;
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -500));
    await tester.pump(const Duration(milliseconds: 200));

    expect(tester.getTopLeft(find.byKey(const ValueKey('my_post_close_button'))).dy, closeTop);
    final scrollViewport = tester.getRect(find.byType(MateoViewSurface));
    expect(scrollViewport.top, lessThan(closeTop));
    expect(tester.getTopLeft(find.byType(MyPostHeaderSurface)).dy, lessThan(cardTop));
    expect(find.text(detail.description), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('card shadow has clearance above the scroll viewport edge', (tester) async {
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final summary = UserJobSummaryDto.fixture();
    final detail = UserJobDto.fixture();
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(detail)))],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();

    final viewportTop = tester.getTopLeft(find.byType(MateoViewSurface)).dy;
    final cardTop = tester.getTopLeft(find.byType(MyPostHeaderSurface)).dy;
    expect(cardTop - viewportTop, greaterThanOrEqualTo(32));
  });

  testWidgets('card fade reaches full opacity before the body', (tester) async {
    final summary = UserJobSummaryDto.fixture().copyWith(title: 'Garçom');
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          myPostStateProvider(summary.jobId).overrideWith(() => FakeMyPostState(AsyncData(UserJobDto.fixture()))),
        ],
        child: MyPostView(summary: summary),
      ),
    );
    await tester.pump();
    final fadeFinder = find.byKey(const ValueKey('my_post_card_fade'));
    final fade = tester.widget<DecoratedBox>(fadeFinder);
    final gradient = (fade.decoration as BoxDecoration).gradient! as LinearGradient;
    final fadeRect = tester.getRect(fadeFinder);
    final opaqueTop = fadeRect.top + fadeRect.height * gradient.stops![1];
    expect(gradient.colors[1].a, 1);
    expect(opaqueTop, lessThan(tester.getTopLeft(find.byType(MyPostDetailChips)).dy));
    expect(
      fadeRect.bottom,
      greaterThan(tester.getBottomLeft(find.byKey(const ValueKey('my_post_header_card'))).dy + 64),
    );
  });
}
