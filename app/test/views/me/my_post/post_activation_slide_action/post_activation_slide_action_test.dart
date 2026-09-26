import 'dart:async';

import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:cataqui_app/views/me/my_post/post_activation_slide_action/post_activation_slide_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../../../utils/test_app.dart';
import '../fake_my_post_state.dart';

void main() {
  final i18n = AppLocale.ptBr.buildSync().me.myPost.activationSlide;

  testWidgets('an incomplete archive slide springs back without requesting', (tester) async {
    final fakeState = await _ActionTestHarness.pumpAction(tester, status: JobStatus.active);

    await _ActionTestHarness.slide(tester, toRight: false, distance: 100);
    await tester.pump(const Duration(milliseconds: 400));

    expect(fakeState.changeStatusCalls, 0);
    expect(find.text(i18n.archive), findsOneWidget);
    expect(find.byType(MateoLoadingIndicator), findsNothing);
  });

  testWidgets('thumb movement emits light ticks during drag and automatic return', (tester) async {
    final hapticCalls = _ActionTestHarness.recordHapticCalls(tester);
    final fakeState = await _ActionTestHarness.pumpAction(tester, status: JobStatus.archived);

    final rect = tester.getRect(find.byType(PostActivationSlideAction));
    final gesture = await tester.startGesture(Offset(rect.left + 26, rect.center.dy));
    for (var step = 0; step < 3; step++) {
      await gesture.moveBy(const Offset(60, 0));
      await tester.pump();
    }
    final tickCount = hapticCalls.length;
    expect(tickCount, greaterThanOrEqualTo(2));
    expect(hapticCalls.map((call) => call.arguments), everyElement('HapticFeedbackType.selectionClick'));

    await gesture.up();
    for (var frame = 0; frame < 4; frame++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(hapticCalls.length, greaterThan(tickCount));
    await tester.pumpAndSettle();
    final settledTickCount = hapticCalls.length;
    await tester.pump(const Duration(milliseconds: 100));
    expect(hapticCalls, hasLength(settledTickCount));
    expect(fakeState.changeStatusCalls, 0);
  });

  testWidgets('archive starts once at the end and reverses into activation', (tester) async {
    final hapticCalls = _ActionTestHarness.recordHapticCalls(tester);
    final response = Completer<void>();
    final fakeState = await _ActionTestHarness.pumpAction(
      tester,
      status: JobStatus.active,
      onChangeStatus: (_) => response.future,
    );

    await _ActionTestHarness.slide(tester, toRight: false, distance: 310);

    expect(fakeState.changeStatusCalls, 1);
    expect(find.byType(MateoLoadingIndicator), findsOneWidget);
    await _ActionTestHarness.slide(tester, toRight: false, distance: 310);
    expect(fakeState.changeStatusCalls, 1);
    expect(hapticCalls.where((call) => call.arguments == 'HapticFeedbackType.successNotification'), isEmpty);

    response.complete();
    await tester.pump();
    expect(hapticCalls.where((call) => call.arguments == 'HapticFeedbackType.successNotification'), hasLength(1));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_ActionTestHarness.arrowHorizontalDirection(tester), greaterThan(0.9));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(i18n.activate), findsOneWidget);
    expect(find.byType(MateoLoadingIndicator), findsNothing);
    expect(_ActionTestHarness.arrowHorizontalDirection(tester), closeTo(1, 0.001));
  });

  testWidgets('activation reverses into an archive action on the right', (tester) async {
    final fakeState = await _ActionTestHarness.pumpAction(tester, status: JobStatus.archived);

    await _ActionTestHarness.slide(tester, toRight: true, distance: 310);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_ActionTestHarness.arrowHorizontalDirection(tester), lessThan(-0.9));
    await tester.pump(const Duration(milliseconds: 100));

    expect(fakeState.changeStatusCalls, 1);
    expect(find.text(i18n.archive), findsOneWidget);
    expect(find.byType(MateoLoadingIndicator), findsNothing);
    expect(_ActionTestHarness.arrowHorizontalDirection(tester), closeTo(-1, 0.001));
  });

  testWidgets('failed activation shows a toast and resets to the archived side', (tester) async {
    final hapticCalls = _ActionTestHarness.recordHapticCalls(tester);
    final response = Completer<void>();
    final fakeState = await _ActionTestHarness.pumpAction(
      tester,
      status: JobStatus.archived,
      onChangeStatus: (_) => response.future,
    );

    await _ActionTestHarness.slide(tester, toRight: true, distance: 310);
    expect(find.byType(MateoLoadingIndicator), findsOneWidget);

    response.completeError(StateError('offline'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(fakeState.changeStatusCalls, 1);
    expect(find.text(i18n.activate), findsOneWidget);
    expect(find.text(i18n.activateError), findsOneWidget);
    expect(find.byType(MateoLoadingIndicator), findsNothing);
    expect(hapticCalls.where((call) => call.arguments == 'HapticFeedbackType.successNotification'), isEmpty);
  });
}

abstract final class _ActionTestHarness {
  static const jobId = 'slide-job';

  static List<MethodCall> recordHapticCalls(WidgetTester tester) {
    final hapticCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') hapticCalls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    return hapticCalls;
  }

  static Future<FakeMyPostState> pumpAction(
    WidgetTester tester, {
    required JobStatus status,
    Future<void> Function(JobStatus)? onChangeStatus,
  }) async {
    final fakeState = FakeMyPostState(
      AsyncData(UserJobDto.fixture().copyWith(jobId: jobId, status: status)),
      onChangeStatus: onChangeStatus,
    );
    await tester.pumpWidget(
      TestApp(
        providerOverrides: [myPostStateProvider(jobId).overrideWith(() => fakeState)],
        child: Center(
          child: SizedBox(
            width: 350,
            child: Consumer(
              builder: (context, ref, _) => PostActivationSlideAction(
                jobId: jobId,
                status: ref.watch(myPostStateProvider(jobId)).requireValue.detail.status,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return fakeState;
  }

  static Future<void> slide(WidgetTester tester, {required bool toRight, required double distance}) async {
    final rect = tester.getRect(find.byType(PostActivationSlideAction));
    final start = Offset(toRight ? rect.left + 26 : rect.right - 26, rect.center.dy);
    final gesture = await tester.startGesture(start);
    await gesture.moveBy(Offset(toRight ? distance : -distance, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
  }

  static double arrowHorizontalDirection(WidgetTester tester) {
    final arrow = find.byType(MateoIcon);
    final rotation = find.ancestor(of: arrow, matching: find.byType(Transform));
    return tester.widget<Transform>(rotation.first).transform.entry(0, 0);
  }
}
