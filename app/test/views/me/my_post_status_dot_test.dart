import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/me/widgets/post_status_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';

void main() {
  late Translations i18n;

  setUpAll(() => i18n = AppLocale.ptBr.buildSync());

  testWidgets('when a job is active, it should show a single green status dot', (tester) async {
    await tester.pumpWidget(
      const TestApp.screen(
        child: Center(child: MyPostStatusDot(status: JobStatus.active)),
      ),
    );

    final chip = find.byType(MyPostStatusDot);
    final theme = MateoTheme.of(tester.element(chip));
    final dot = find.byKey(const ValueKey('my_post_status_dot'));
    expect(tester.getSize(dot), const Size(10, 10));
    expect(find.text(i18n.me.activePostStatus), findsNothing);
    expect(find.bySemanticsLabel(i18n.me.activePostStatus), findsOneWidget);
    expect(find.descendant(of: chip, matching: find.byType(MateoSurface)), findsNothing);
    expect(
      (tester.widget<DecoratedBox>(find.descendant(of: chip, matching: find.byType(DecoratedBox))).decoration
              as BoxDecoration)
          .color,
      theme.colorScheme.text.profit,
    );
  });

  testWidgets('when a job is archived, it should show a single gray status dot', (tester) async {
    await tester.pumpWidget(
      const TestApp.screen(
        child: Center(child: MyPostStatusDot(status: JobStatus.archived)),
      ),
    );

    final chip = find.byType(MyPostStatusDot);
    final theme = MateoTheme.of(tester.element(chip));
    expect(tester.getSize(find.byKey(const ValueKey('my_post_status_dot'))), const Size(10, 10));
    expect(find.text(i18n.me.inactivePostStatus), findsNothing);
    expect(find.bySemanticsLabel(i18n.me.inactivePostStatus), findsOneWidget);
    expect(
      (tester.widget<DecoratedBox>(find.descendant(of: chip, matching: find.byType(DecoratedBox))).decoration
              as BoxDecoration)
          .color,
      theme.colorScheme.text.tertiary,
    );
  });

  testWidgets('when a job status is unknown, it should use the archived presentation', (tester) async {
    await tester.pumpWidget(
      const TestApp.screen(
        child: Center(child: MyPostStatusDot(status: JobStatus.unknown)),
      ),
    );

    expect(find.bySemanticsLabel(i18n.me.inactivePostStatus), findsOneWidget);
    final dot = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(MyPostStatusDot), matching: find.byType(DecoratedBox)),
    );
    expect(
      (dot.decoration as BoxDecoration).color,
      MateoTheme.of(tester.element(find.byType(MyPostStatusDot))).colorScheme.text.tertiary,
    );
  });
}
