import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/create_job/create_job_data.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/payment/widgets/flexible_payment_values_wheel/flexible_payment_values_wheel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../test/utils/test_app.dart';
import '../../test/views/create_job/create_job_test_state.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'when the flexible payment wheel runs continuously, it should keep p99 frame phases inside the native budget',
    (tester) async {
      if (!kProfileMode) throw StateError('Run this benchmark in profile mode.');

      final refreshRate = tester.view.display.refreshRate;
      kBuildBudget = Duration(microseconds: (Duration.microsecondsPerSecond / refreshRate).round());
      binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.benchmarkLive;
      try {
        await binding.watchPerformance(() async {
          await tester.pumpWidget(
            TestApp.screen(
              mediaQueryData: MediaQueryData(
                size: tester.view.physicalSize / tester.view.devicePixelRatio,
                devicePixelRatio: tester.view.devicePixelRatio,
                textScaler: TextScaler.noScaling,
                disableAnimations: false,
              ),
              providerOverrides: [
                translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
                createJobStateProvider.overrideWith(
                  () => CreateJobTestState(initialData: const CreateJobData(currencyCode: 'BRL')),
                ),
              ],
              child: const Center(child: FlexiblePaymentValuesWheel()),
            ),
          );
          await tester.pump();
          await Future<void>.delayed(const Duration(seconds: 1));
        }, reportKey: 'flexible_payment_values_wheel_first_second');
        await Future<void>.delayed(const Duration(seconds: 17));
        final renderer = tester.renderObject<FlexiblePaymentValuesWheelRenderBox>(
          find.byKey(const ValueKey('flexible_payment_values_wheel_renderer')),
        );
        await binding.watchPerformance(
          () => Future<void>.delayed(const Duration(seconds: 32)),
          reportKey: 'flexible_payment_values_wheel',
        );
        binding.reportData!['flexible_payment_values_wheel_environment'] = {
          'refresh_rate_hz': refreshRate,
          'frame_budget_micros': kBuildBudget.inMicroseconds,
          'physical_width': tester.view.physicalSize.width,
          'physical_height': tester.view.physicalSize.height,
          'device_pixel_ratio': tester.view.devicePixelRatio,
          'atlas_ready': renderer.debugIsAtlasReady,
          'direct_painter_count': renderer.debugDirectPainterCount,
        };

        final steadySummary = binding.reportData!['flexible_payment_values_wheel']! as Map<String, Object?>;
        final frameBudgetMillis = kBuildBudget.inMicroseconds / Duration.microsecondsPerMillisecond;
        expect(
          (
            renderer.debugIsAtlasReady,
            renderer.debugDirectPainterCount,
            (steadySummary['99th_percentile_frame_build_time_millis']! as num).toDouble() <= frameBudgetMillis,
            (steadySummary['99th_percentile_frame_rasterizer_time_millis']! as num).toDouble() <= frameBudgetMillis,
          ),
          (true, 0, true, true),
        );
      } finally {
        binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fadePointers;
      }
    },
  );
}
