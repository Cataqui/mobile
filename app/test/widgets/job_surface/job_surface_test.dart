import 'package:cataqui_app/views/job/enums/job_view_morph_tag.dart';
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
      final fadeTag = JobViewMorphTag.edgeFade.valueFor(jobId: jobId);
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
      final fadeTag = JobViewMorphTag.edgeFade.valueFor(jobId: jobId);
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

      expect((firstKey, secondKey), equals((ValueKey(fadeTag), ValueKey(fadeTag))));
    });
  });
}
