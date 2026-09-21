import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/add_contact/add_contact_route.dart';
import 'package:cataqui_app/views/add_contact/add_contact_view.dart';
import 'package:cataqui_app/views/post/contact/post_contact_view.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import '../post/contact/post_contact_test_helpers.dart';

void main() {
  late MockUserRepository userRepository;

  setUp(() {
    userRepository = MockUserRepository();
    PostContactTestHelpers.stubContacts(userRepository);
  });

  for (final systemBack in [false, true]) {
    testWidgets(
      'Add contact expands from the sheet and ${systemBack ? 'system back' : 'close'} restores the sheet and draft',
      (tester) async {
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(400, 800);
        addTearDown(tester.view.reset);
        final observer = MateoNavigatorObserver();
        final router = GoRouter(
          initialLocation: '/post',
          routes: [$postRoute, $addContactRoute],
          observers: [observer],
        );
        addTearDown(router.dispose);
        await tester.pumpWidget(
          TestApp.router(
            routerConfig: router,
            providerOverrides: [userRepositoryProvider.overrideWithValue(userRepository)],
          ),
        );
        await tester.pumpAndSettle();
        final container = ProviderScope.containerOf(tester.element(find.byType(PostView)));
        container.read(postStateProvider.notifier).setDescription('Ajudar na mudança');
        container
            .read(postStateProvider.notifier)
            .selectContact(contactMethod: .whatsapp, identifier: '+5511987654321');
        await tester.pump();
        final draft = container.read(postStateProvider);
        await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
        await tester.pumpAndSettle();
        final sheetState = tester.state(find.byType(PostContactView));
        final sheetSurface = find.byKey(const ValueKey('post_contact_sheet_surface'));
        final sheetBounds = tester.getRect(sheetSurface);
        await tester.tap(find.byKey(const ValueKey('post_contact_add_button')));
        await tester.pump();
        await tester.pump();
        expect(find.byType(AddContactView), findsOneWidget);
        final route = ModalRoute.of(tester.element(find.byType(AddContactView)))!;
        expect(route.settings, isA<MateoPage<void>>());
        final flight = find.byWidgetPredicate((widget) => widget.runtimeType.toString() == '_MorphFlightBoundary');
        await tester.pump(const Duration(milliseconds: 100));
        expect(tester.getRect(flight).height, greaterThan(sheetBounds.height));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(EditableText), '11987654321');
        await tester.pump();
        expect(container.read(postStateProvider), draft);
        if (systemBack) {
          await tester.binding.handlePopRoute();
        } else {
          await tester.tap(find.byKey(const ValueKey('add_contact_close_button')));
        }
        await tester.pump();
        await tester.pump();
        await tester.pumpAndSettle();
        expect(find.byType(AddContactView), findsNothing);
        expect(tester.state(find.byType(PostContactView)), same(sheetState));
        expect(container.read(postStateProvider), draft);
      },
    );
  }

  testWidgets('saving sets the WhatsApp number and returns directly to the job form', (tester) async {
    final router = GoRouter(
      initialLocation: '/post',
      routes: [$postRoute, $addContactRoute],
      observers: [MateoNavigatorObserver()],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      TestApp.router(
        routerConfig: router,
        providerOverrides: [userRepositoryProvider.overrideWithValue(userRepository)],
      ),
    );
    await tester.pumpAndSettle();
    final container = ProviderScope.containerOf(tester.element(find.byType(PostView)));
    container.read(postStateProvider.notifier).setDescription('Ajudar na mudanca');
    await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post_contact_add_button')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), '+5511912345678');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('add_contact_save_button')));
    expect(find.byType(PostContactView), findsNothing);
    await tester.pumpAndSettle();
    expect(find.byType(AddContactView), findsNothing);
    expect(find.byType(PostContactView), findsNothing);
    expect(find.byType(PostView), findsOneWidget);
    expect(router.canPop(), isFalse);
    expect(container.read(postStateProvider).descriptionText, 'Ajudar na mudanca');
    expect(container.read(postStateProvider).contact, (
      contactMethod: JobContactMethod.whatsapp,
      identifier: '+5511912345678',
    ));
  });

  testWidgets('closing a direct entry returns to the job form', (tester) async {
    final router = GoRouter(
      initialLocation: '/add-contact',
      routes: [$postRoute, $addContactRoute],
      observers: [MateoNavigatorObserver()],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(TestApp.router(routerConfig: router));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add_contact_close_button')));
    await tester.pumpAndSettle();
    expect(find.byType(PostView), findsOneWidget);
  });
}
