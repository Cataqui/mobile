import 'package:cataqui_app/views/job/widgets/job_surface/job_surface.dart';
import 'package:cataqui_app/views/job/widgets/job_surface/job_surface_edge_fade.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

void main() {
  final colorScheme = MateoColorScheme.light();

  group('JobSurface', () {
    testWidgets('when an edge fade is configured, it should paint the fade layer last', (tester) async {
      const jobId = 'job-surface';
      const fadeTag = 'job-$jobId-edge-fade';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobSurface(
              jobId: jobId,
              decoration: BoxDecoration(color: colorScheme.background, borderRadius: BorderRadius.circular(38)),
              edgeFadeStyle: MateoEdgeFadeStyle(color: colorScheme.background, mainAxisExtent: 80),
              fadeTop: true,
              child: const Text('Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final stack = tester.widget<Stack>(
        find.descendant(of: find.byType(JobSurface), matching: find.byType(Stack)).first,
      );

      expect(
        stack.children.last,
        isA<Positioned>().having(
          (positioned) => positioned.child,
          'child',
          isA<Morph>().having((morph) => morph.tag, 'tag', fadeTag),
        ),
      );
    });

    testWidgets('when an edge fade is configured, it should ignore pointer input', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: JobSurface(
              jobId: 'job-surface',
              decoration: BoxDecoration(color: colorScheme.background),
              edgeFadeStyle: MateoEdgeFadeStyle(color: colorScheme.background, mainAxisExtent: 80),
              fadeTop: true,
              child: const Text('Content'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.descendant(of: find.byType(JobSurfaceEdgeFade), matching: find.byType(IgnorePointer)), findsWidgets);
    });

    testWidgets('when an edge fade rebuilds, it should keep a stable transition identity', (tester) async {
      const jobId = 'job-surface';
      const fadeTag = 'job-$jobId-edge-fade';
      Widget buildSurface(Color color) {
        return MaterialApp(
          home: Scaffold(
            body: JobSurface(
              jobId: jobId,
              decoration: BoxDecoration(color: color),
              edgeFadeStyle: MateoEdgeFadeStyle(color: color, mainAxisExtent: 80),
              fadeTop: true,
              child: const Text('Content'),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildSurface(colorScheme.background));
      await tester.pumpAndSettle();
      final firstKey = tester
          .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == fadeTag))
          .child
          .key;
      await tester.pumpWidget(buildSurface(colorScheme.text.secondary));
      await tester.pumpAndSettle();
      final secondKey = tester
          .widget<Morph>(find.byWidgetPredicate((widget) => widget is Morph && widget.tag == fadeTag))
          .child
          .key;

      expect((firstKey, secondKey), equals((const ValueKey(fadeTag), const ValueKey(fadeTag))));
    });

    testWidgets('when dragging the job surface downward, it should round the visible surface before closing', (
      tester,
    ) async {
      const jobId = 'swipe-job-surface';
      const surfaceTag = 'job-$jobId-surface';
      const dragTargetKey = ValueKey('swipe-job-surface-drag-target');
      await tester.pumpWidget(
        MaterialApp(
          home: MateoSwipeToPopSurface(
            borderRadius: const BorderRadius.all(Radius.circular(40)),
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  key: dragTargetKey,
                  width: 240,
                  height: 240,
                  child: JobSurface(
                    jobId: jobId,
                    decoration: BoxDecoration(color: colorScheme.background),
                    child: const Text('Content'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(find.byKey(dragTargetKey)));
      await gesture.moveBy(const Offset(0, 40));
      await tester.pump();
      final container = tester.widget<Container>(find.byKey(const ValueKey(surfaceTag)));

      expect((container.decoration! as BoxDecoration).borderRadius, isNot(BorderRadius.zero));
      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
