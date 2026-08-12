import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/core/repositories/job_repository.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_data.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_modal.dart';
import 'package:cataqui_app/views/job_creation_flow/job_creation_flow_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';

abstract final class JobCreationFlowModalTestHelpers {
  static const openButtonKey = ValueKey('open_job_creation_flow');

  static Future<void> pumpSheet(
    WidgetTester tester, {
    double keyboardInset = 0,
    bool disableAnimations = true,
    JobCreationFlowData? initialFlowData,
    JobRepository? jobRepository,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844)
      ..padding = FakeViewPadding(top: 47, bottom: keyboardInset > 0 ? 0 : 34)
      ..viewPadding = const FakeViewPadding(top: 47, bottom: 34)
      ..viewInsets = FakeViewPadding(bottom: keyboardInset);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      buildApp(
        keyboardInset: keyboardInset,
        disableAnimations: disableAnimations,
        initialFlowData: initialFlowData,
        jobRepository: jobRepository,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(openButtonKey));
    await tester.pumpAndSettle();
  }

  static Widget buildApp({
    double keyboardInset = 0,
    bool disableAnimations = true,
    JobCreationFlowData? initialFlowData,
    JobRepository? jobRepository,
  }) {
    return TestApp.screen(
      mediaQueryData: MediaQueryData(
        size: const Size(390, 844),
        devicePixelRatio: 1,
        padding: EdgeInsets.only(top: 47, bottom: keyboardInset > 0 ? 0 : 34),
        viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
        textScaler: TextScaler.noScaling,
        disableAnimations: disableAnimations,
      ),
      providerOverrides: [
        translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
        if (jobRepository != null) jobRepositoryProvider.overrideWithValue(jobRepository),
        if (initialFlowData != null) jobCreationFlowStateProvider.overrideWithValue(initialFlowData),
      ],
      child: Builder(
        builder: (context) {
          return Scaffold(
            floatingActionButton: MateoFloatingActionButton(
              key: openButtonKey,
              semanticLabel: AppLocale.ptBr.buildSync().feed.jobCreationButtonSemanticLabel,
              onPressed: () => unawaited(JobCreationFlowModal.show(context)),
              iconBuilder: (state) =>
                  MateoIcon.plusSignal(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
            ),
          );
        },
      ),
    );
  }
}
