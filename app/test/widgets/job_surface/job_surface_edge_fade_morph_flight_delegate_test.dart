import 'dart:ui' as ui;

import 'package:cataqui_app/widgets/job_surface/job_surface_edge_fade.dart';
import 'package:cataqui_app/widgets/job_surface/job_surface_edge_fade_morph_flight_delegate.dart';
import 'package:cataqui_app/widgets/job_surface/job_surface_edge_fade_morph_flight_delegate_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers extends MorphFlightDelegate<JobSurfaceEdgeFadeMorphProperties> {
  _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers(this.capturedProperties);

  final List<JobSurfaceEdgeFadeMorphProperties> capturedProperties;

  static const dragTargetKey = ValueKey('job_surface_edge_fade_drag_target');
  static const flightKey = ValueKey('job_surface_edge_fade_flight');
  static const captureKey = ValueKey('job_surface_edge_fade_capture');
  static final surfaceColor = MateoColorScheme.light().background;
  static final contrastColor = MateoColorScheme.light().text.primary;

  static final sourceProperties = (
    borderRadius: const BorderRadius.all(Radius.circular(38)),
    topStyle: MateoEdgeFadeStyle(
      color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
      mainAxisExtent: 0,
    ),
    bottomStyle: MateoEdgeFadeStyle(
      color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
      mainAxisExtent: 0,
    ),
    switchThreshold: 1.0,
  );
  static final destinationProperties = (
    borderRadius: BorderRadius.zero,
    topStyle: MateoEdgeFadeStyle(
      color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
      mainAxisExtent: 100,
    ),
    bottomStyle: MateoEdgeFadeStyle(
      color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
      mainAxisExtent: 70,
    ),
    switchThreshold: 1.0,
  );

  static Future<JobSurfaceEdgeFadeMorphProperties> captureProperties({
    required WidgetTester tester,
    required ValueNotifier<int> captureGeneration,
    required List<JobSurfaceEdgeFadeMorphProperties> capturedProperties,
  }) async {
    capturedProperties.clear();
    captureGeneration.value += 1;
    await tester.pump();
    await tester.pump();
    return capturedProperties.first;
  }

  static Widget app({
    required ValueNotifier<int> captureGeneration,
    required List<JobSurfaceEdgeFadeMorphProperties> capturedProperties,
    BorderRadius borderRadius = BorderRadius.zero,
    MateoEdgeFadeStyle? topStyle,
    MateoEdgeFadeStyle? bottomStyle,
  }) {
    final flightDelegate = _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers(capturedProperties);
    return MaterialApp(
      home: Scaffold(
        body: SizedBox.expand(
          child: ValueListenableBuilder<int>(
            valueListenable: captureGeneration,
            builder: (context, generation, child) {
              return Morph(
                tag: _captureTag,
                flightDelegate: flightDelegate,
                child: JobSurfaceEdgeFade(
                  key: ValueKey('job_surface_edge_fade_$generation'),
                  borderRadius: borderRadius,
                  absentStyle: MateoEdgeFadeStyle(
                    color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
                    mainAxisExtent: 80,
                  ),
                  topStyle: topStyle,
                  bottomStyle: bottomStyle,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Widget swipeApp({
    required ValueNotifier<int> captureGeneration,
    required List<JobSurfaceEdgeFadeMorphProperties> capturedProperties,
  }) {
    final flightDelegate = _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers(capturedProperties);
    return MaterialApp(
      home: MateoSwipeToPopSurface(
        borderRadius: const BorderRadius.all(Radius.circular(40)),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              key: dragTargetKey,
              width: 240,
              height: 240,
              child: ValueListenableBuilder<int>(
                valueListenable: captureGeneration,
                builder: (context, generation, child) {
                  return Morph(
                    tag: _captureTag,
                    flightDelegate: flightDelegate,
                    child: JobSurfaceEdgeFade(
                      key: ValueKey('job_surface_edge_fade_$generation'),
                      borderRadius: BorderRadius.zero,
                      absentStyle: MateoEdgeFadeStyle(
                        color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
                        mainAxisExtent: 80,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  static MorphFlight<JobSurfaceEdgeFadeMorphProperties> flight(double progress) {
    const size = Size(160, 200);
    final bounds = Offset.zero & size;
    const delegate = JobSurfaceEdgeFadeMorphFlightDelegate();
    return MorphFlight<JobSurfaceEdgeFadeMorphProperties>(
      source: MorphEndpoint<JobSurfaceEdgeFadeMorphProperties>(
        properties: sourceProperties,
        bounds: bounds,
        localSize: size,
        transform: Matrix4.identity(),
        axisScale: const Offset(1, 1),
      ),
      destination: MorphEndpoint<JobSurfaceEdgeFadeMorphProperties>(
        properties: destinationProperties,
        bounds: bounds,
        localSize: size,
        transform: Matrix4.identity(),
        axisScale: const Offset(1, 1),
      ),
      kind: MorphFlightKind.sameScreen,
      animation: AlwaysStoppedAnimation<double>(progress),
      flightDelegate: delegate,
    );
  }

  static Widget flightApp(double progress) {
    const delegate = JobSurfaceEdgeFadeMorphFlightDelegate();
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: flightKey,
            width: 160,
            height: 200,
            child: Builder(builder: (context) => delegate.buildFlight(context, flight(progress))),
          ),
        ),
      ),
    );
  }

  static Future<bool> retainedPainterMatchesWidget(WidgetTester tester) async {
    const delegate = JobSurfaceEdgeFadeMorphFlightDelegate();
    final properties = delegate.lerp(sourceProperties, destinationProperties, 0.5);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.contrastColor,
          body: Center(
            child: RepaintBoundary(
              key: captureKey,
              child: SizedBox(
                width: 320,
                height: 200,
                child: Row(
                  children: [
                    SizedBox(
                      width: 160,
                      height: 200,
                      child: Builder(builder: (context) => delegate.buildFlight(context, flight(0.5))),
                    ),
                    SizedBox(
                      width: 160,
                      height: 200,
                      child: JobSurfaceEdgeFade(
                        borderRadius: properties.borderRadius,
                        absentStyle: properties.topStyle,
                        topStyle: properties.topStyle,
                        bottomStyle: properties.bottomStyle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(captureKey));
    return (await tester.runAsync(() async {
      final image = await boundary.toImage();
      final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      image.dispose();
      final pixels = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      const halfWidthInBytes = 160 * 4;
      const rowWidthInBytes = 320 * 4;
      for (var row = 0; row < 200; row++) {
        final leftStart = row * rowWidthInBytes;
        final rightStart = leftStart + halfWidthInBytes;
        for (var byte = 0; byte < halfWidthInBytes; byte++) {
          if (pixels[leftStart + byte] != pixels[rightStart + byte]) return false;
        }
      }
      return true;
    }))!;
  }

  static const _captureTag = 'job_surface_edge_fade_properties';

  @override
  JobSurfaceEdgeFadeMorphProperties properties(MorphEndpointContext endpoint) {
    final properties = const JobSurfaceEdgeFadeMorphFlightDelegate().properties(endpoint);
    capturedProperties.add(properties);
    return properties;
  }

  @override
  JobSurfaceEdgeFadeMorphProperties lerp(
    JobSurfaceEdgeFadeMorphProperties source,
    JobSurfaceEdgeFadeMorphProperties destination,
    double progress,
  ) {
    return const JobSurfaceEdgeFadeMorphFlightDelegate().lerp(source, destination, progress);
  }

  @override
  Widget buildFlight(BuildContext context, MorphFlight<JobSurfaceEdgeFadeMorphProperties> flight) {
    return const JobSurfaceEdgeFadeMorphFlightDelegate().buildFlight(context, flight);
  }
}

void main() {
  group('JobSurfaceEdgeFadeMorphFlightDelegate', () {
    late ValueNotifier<int> captureGeneration;
    late List<JobSurfaceEdgeFadeMorphProperties> capturedProperties;

    setUp(() {
      captureGeneration = ValueNotifier<int>(0);
      capturedProperties = <JobSurfaceEdgeFadeMorphProperties>[];
    });

    tearDown(() => captureGeneration.dispose());

    testWidgets('when the top fade is absent, it should capture zero extent', (tester) async {
      await tester.pumpWidget(
        _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.app(
          captureGeneration: captureGeneration,
          capturedProperties: capturedProperties,
          bottomStyle: MateoEdgeFadeStyle(
            color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
            mainAxisExtent: 60,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final properties = await _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.captureProperties(
        tester: tester,
        captureGeneration: captureGeneration,
        capturedProperties: capturedProperties,
      );

      expect(properties.topStyle.mainAxisExtent, equals(0));
    });

    testWidgets('when the bottom fade is absent, it should capture zero extent', (tester) async {
      await tester.pumpWidget(
        _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.app(
          captureGeneration: captureGeneration,
          capturedProperties: capturedProperties,
          topStyle: MateoEdgeFadeStyle(
            color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
            mainAxisExtent: 100,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final properties = await _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.captureProperties(
        tester: tester,
        captureGeneration: captureGeneration,
        capturedProperties: capturedProperties,
      );

      expect(properties.bottomStyle.mainAxisExtent, equals(0));
    });

    test('when opposite fades interpolate halfway, it should interpolate both extents', () {
      const delegate = JobSurfaceEdgeFadeMorphFlightDelegate();
      final source = (
        borderRadius: BorderRadius.zero,
        topStyle: MateoEdgeFadeStyle(
          color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
          mainAxisExtent: 0,
        ),
        bottomStyle: MateoEdgeFadeStyle(
          color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
          mainAxisExtent: 60,
        ),
        switchThreshold: 1.0,
      );
      final destination = (
        borderRadius: BorderRadius.zero,
        topStyle: MateoEdgeFadeStyle(
          color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
          mainAxisExtent: 100,
        ),
        bottomStyle: MateoEdgeFadeStyle(
          color: _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.surfaceColor,
          mainAxisExtent: 0,
        ),
        switchThreshold: 1.0,
      );

      final properties = delegate.lerp(source, destination, 0.5);

      expect((properties.topStyle.mainAxisExtent, properties.bottomStyle.mainAxisExtent), equals((50, 30)));
    });

    testWidgets('when a swipe preview is active, it should capture the preview radius', (tester) async {
      await tester.pumpWidget(
        _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.swipeApp(
          captureGeneration: captureGeneration,
          capturedProperties: capturedProperties,
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.dragTargetKey)),
      );
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();

      final properties = await _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.captureProperties(
        tester: tester,
        captureGeneration: captureGeneration,
        capturedProperties: capturedProperties,
      );

      expect(properties.borderRadius.topLeft.x, greaterThan(0));
      await gesture.up();
    });

    testWidgets('when an edge-fade transition is active, it should paint without rebuilding edge-fade widgets', (
      tester,
    ) async {
      await tester.pumpWidget(_JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.flightApp(0.5));
      await tester.pumpAndSettle();
      final flight = find.byKey(_JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.flightKey);

      expect((
        find.descendant(of: flight, matching: find.byType(CustomPaint)).evaluate().length,
        find.descendant(of: flight, matching: find.byType(JobSurfaceEdgeFade)).evaluate().length,
      ), equals((1, 0)));
    });

    testWidgets('when an edge fade is halfway through its transition, it should match the resting fade composition', (
      tester,
    ) async {
      final retainedPainterMatchesWidget =
          await _JobSurfaceEdgeFadeMorphFlightDelegateTestHelpers.retainedPainterMatchesWidget(tester);

      expect(retainedPainterMatchesWidget, isTrue);
    });
  });
}
