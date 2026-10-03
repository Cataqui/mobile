import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/views/me/my_post/my_post_header_surface.dart';
import 'package:cataqui_app/views/me/widgets/post_status_dot.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../utils/test_app.dart';

void main() {
  testWidgets('pulsing status dot does not repaint the static post header', (tester) async {
    final headerBoundaryKey = GlobalKey();
    await tester.pumpWidget(
      TestApp.screen(
        child: Center(
          child: RepaintBoundary(
            key: headerBoundaryKey,
            child: SizedBox(
              width: 390,
              child: MyPostHeaderSurface(
                summary: UserJobSummaryDto.fixture().copyWith(status: .active),
                timeAgo: '1 dia atrás',
                payment: r'R$100/dia',
                expansion: 0,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));

    final headerBoundary = (headerBoundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary)
      ..debugResetMetrics();
    await tester.pump(const Duration(milliseconds: 450));
    await tester.pump(const Duration(milliseconds: 450));

    expect(tester.binding.hasScheduledFrame, isTrue);
    expect(headerBoundary.debugAsymmetricPaintCount, 0);
    final dotBoundary = tester.renderObject<RenderRepaintBoundary>(
      find.descendant(of: find.byType(MyPostStatusDot), matching: find.byType(RepaintBoundary)),
    );
    expect(dotBoundary.debugAsymmetricPaintCount, greaterThan(0));
  });
}
