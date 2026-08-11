import 'package:cataqui_app/core/providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../mocks.dart';
import 'test_app.dart';

void main() {
  testWidgets('when a provider override is supplied, it should expose that dependency to the test app', (tester) async {
    final secureStorage = MockFlutterSecureStorage();
    Object? resolvedSecureStorage;

    await tester.pumpWidget(
      TestApp(
        providerOverrides: [secureStorageProvider.overrideWithValue(secureStorage)],
        child: Consumer(
          builder: (context, ref, child) {
            resolvedSecureStorage = ref.watch(secureStorageProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(resolvedSecureStorage, same(secureStorage));
  });

  testWidgets('when separate test apps are mounted, it should give each isolated default dependencies', (tester) async {
    Object? firstSecureStorage;
    Object? secondSecureStorage;

    await tester.pumpWidget(
      TestApp(
        child: Consumer(
          builder: (context, ref, child) {
            firstSecureStorage = ref.watch(secureStorageProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      TestApp(
        child: Consumer(
          builder: (context, ref, child) {
            secondSecureStorage = ref.watch(secureStorageProvider);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(secondSecureStorage, isNot(same(firstSecureStorage)));
  });
}
