import 'package:cataqui_app/views/create_job/payment/create_job_payment_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'when payment icons are precached at their rendered sizes, it should populate every matching decoded cache entry',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      addTearDown(() {
        imageCache
          ..clear()
          ..clearLiveImages();
      });
      imageCache
        ..clear()
        ..clearLiveImages();

      await tester.pumpWidget(const MaterialApp(home: SizedBox(key: ValueKey('payment_icon_precache_context'))));
      final context = tester.element(find.byKey(const ValueKey('payment_icon_precache_context')));

      await tester.runAsync(() => CreateJobPaymentView.precacheIcons(context));
      await tester.pump();

      final configuration = createLocalImageConfiguration(context);
      final statuses = await Future.wait([
        ResizeImage.resizeIfNeeded(
          27,
          27,
          const AssetImage('assets/icons/padlock.webp'),
        ).obtainCacheStatus(configuration: configuration),
        ResizeImage.resizeIfNeeded(
          27,
          27,
          const AssetImage('assets/icons/bidirecional-horizontal-arrow.webp'),
        ).obtainCacheStatus(configuration: configuration),
        ResizeImage.resizeIfNeeded(
          32,
          32,
          const AssetImage('assets/icons/handshake.webp'),
        ).obtainCacheStatus(configuration: configuration),
        ResizeImage.resizeIfNeeded(
          25,
          25,
          const AssetImage('assets/icons/pencil.webp'),
        ).obtainCacheStatus(configuration: configuration),
      ]);

      expect(statuses.every((status) => status != null && (status.pending || status.keepAlive || status.live)), isTrue);
    },
  );
}
