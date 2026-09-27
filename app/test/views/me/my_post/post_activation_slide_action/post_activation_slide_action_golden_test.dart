import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:cataqui_app/views/me/my_post/post_activation_slide_action/post_activation_slide_action.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../utils/test_app.dart';
import '../fake_my_post_state.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when archived or active, it should show the corresponding resting slide action',
        fileName: 'post_activation_slide_resting_states',
        constraints: const BoxConstraints.tightFor(width: 390, height: 180),
        builder: () => const TestApp.screen(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              mainAxisAlignment: .center,
              children: [
                PostActivationSlideAction(jobId: 'archived-job', status: JobStatus.archived),
                SizedBox(height: 16),
                PostActivationSlideAction(jobId: 'active-job', status: JobStatus.active),
              ],
            ),
          ),
        ),
      );

      goldenTest(
        'when activating a post, it should show the halfway drag state',
        fileName: 'post_activation_slide_mid_drag',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        builder: () => const TestApp.screen(
          child: Center(
            child: SizedBox(
              width: 350,
              child: PostActivationSlideAction(jobId: 'archived-job', status: JobStatus.archived),
            ),
          ),
        ),
        whilePerforming: (tester) async {
          final rect = tester.getRect(find.byType(PostActivationSlideAction));
          final gesture = await tester.startGesture(Offset(rect.left + 26, rect.center.dy));
          await gesture.moveBy(const Offset(140, 0));
          await tester.pump();
          return gesture.up;
        },
      );

      late Completer<void> statusChange;
      goldenTest(
        'when archiving succeeds, it should show the halfway return state',
        fileName: 'post_activation_slide_mid_return',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        builder: () {
          statusChange = Completer<void>();
          return TestApp.screen(
            providerOverrides: [
              myPostStateProvider('active-job').overrideWith(
                () => FakeMyPostState(
                  AsyncData(UserJobDto.fixture().copyWith(jobId: 'active-job', status: JobStatus.active)),
                  onChangeStatus: (_) => statusChange.future,
                ),
              ),
            ],
            child: Center(
              child: SizedBox(
                width: 350,
                child: Consumer(
                  builder: (context, ref, _) => PostActivationSlideAction(
                    jobId: 'active-job',
                    status: ref.watch(myPostStateProvider('active-job')).requireValue.detail.status,
                  ),
                ),
              ),
            ),
          );
        },
        whilePerforming: (tester) async {
          final rect = tester.getRect(find.byType(PostActivationSlideAction));
          final gesture = await tester.startGesture(Offset(rect.right - 26, rect.center.dy));
          await gesture.moveBy(const Offset(-310, 0));
          await tester.pump();
          await gesture.up();
          await tester.pump();
          statusChange.complete();
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 90));
          return null;
        },
      );
    },
  );
}
