import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/views/me/my_post/post_activation_slide_action/post_activation_slide_action.dart';
import 'package:flutter/material.dart';

import '../../../../utils/test_app.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () => goldenTest(
      'post activation slide resting states',
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
    ),
  );
}
