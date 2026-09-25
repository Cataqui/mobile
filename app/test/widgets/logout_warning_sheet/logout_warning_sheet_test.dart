import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/app_storage/app_storage_state.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/logout_warning_sheet/logout_warning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../utils/test_app.dart';
import '../../views/feed/feed_view_test_helpers.dart';
import '../../views/me/fake_app_auth_state.dart';
import 'logout_warning_sheet_test_host.dart';

void main() {
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  testWidgets('opening the reusable sheet shows the localized warning and both actions', (tester) async {
    await tester.pumpWidget(const TestApp.screen(child: LogoutWarningSheetTestHost()));

    await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutWarningSheet), findsOneWidget);
    expect(find.text(i18n.logoutWarningSheet.title), findsOneWidget);
    expect(find.text(i18n.logoutWarningSheet.description), findsOneWidget);
    expect(find.text(i18n.logoutWarningSheet.back), findsOneWidget);
    expect(find.text(i18n.logoutWarningSheet.logout), findsOneWidget);
    expect(find.byType(MateoSheetViewHeader), findsOneWidget);
  });

  testWidgets('opening the sheet triggers one warning haptic', (tester) async {
    final hapticCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') hapticCalls.add(call);
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const TestApp.screen(child: LogoutWarningSheetTestHost()));

    await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutWarningSheet), findsOneWidget);
    expect(hapticCalls, hasLength(1));
    expect(hapticCalls.single.arguments, 'HapticFeedbackType.warningNotification');
  });

  testWidgets('the warning icon shakes only after the sheet route settles', (tester) async {
    await tester.pumpWidget(const TestApp.screen(child: LogoutWarningSheetTestHost()));
    await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
    await tester.pump();

    final sheetRoute = ModalRoute.of(tester.element(find.byType(LogoutWarningSheet)))!;
    final motionFinder = find.descendant(of: find.byType(LogoutWarningSheet), matching: find.byType(Motion));
    final iconFinder = find.descendant(of: motionFinder, matching: find.byType(MateoIcon));
    final motion = tester.widget<Motion>(motionFinder);
    final effect = motion.effect! as ShakeMotionEffect;
    expect(
      (motion.startup, effect.offset, effect.count, effect.damping, effect.duration, effect.curve),
      (MotionStartup.skip, const Offset(3, 0), 5, 1, const Duration(milliseconds: 1700), Curves.easeOutBack),
    );

    await tester.pump(sheetRoute.transitionDuration * 0.5);
    expect(sheetRoute.animation!.status, AnimationStatus.forward);
    expect(tester.getTopLeft(iconFinder).dx - tester.getTopLeft(motionFinder).dx, closeTo(0, 0.01));

    await tester.pump(sheetRoute.transitionDuration);
    expect(sheetRoute.animation!.status, AnimationStatus.completed);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect((tester.getTopLeft(iconFinder).dx - tester.getTopLeft(motionFinder).dx).abs(), greaterThan(0.1));

    await tester.pump(const Duration(milliseconds: 1700));
    expect(tester.getTopLeft(iconFinder).dx - tester.getTopLeft(motionFinder).dx, closeTo(0, 0.01));
  });

  testWidgets('the sheet close button dismisses the warning', (tester) async {
    var closed = false;
    var confirmations = 0;
    final authState = FakeAppAuthState(AuthSessionDto.fixture());
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [appAuthStateProvider.overrideWith(() => authState)],
        child: LogoutWarningSheetTestHost(onClosed: () => closed = true, onConfirmed: () async => confirmations++),
      ),
    );
    await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.descendant(of: find.byType(MateoSheetViewHeader), matching: find.byType(MateoButton)));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutWarningSheet), findsNothing);
    expect(closed, isTrue);
    expect(confirmations, 0);
    expect(authState.currentSession, isNotNull);
  });

  testWidgets('Voltar dismisses the warning', (tester) async {
    var closed = false;
    var confirmations = 0;
    final authState = FakeAppAuthState(AuthSessionDto.fixture());
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [appAuthStateProvider.overrideWith(() => authState)],
        child: LogoutWarningSheetTestHost(onClosed: () => closed = true, onConfirmed: () async => confirmations++),
      ),
    );
    await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('logout_warning_sheet_back_button')));
    await tester.pumpAndSettle();

    expect(find.byType(LogoutWarningSheet), findsNothing);
    expect(closed, isTrue);
    expect(confirmations, 0);
    expect(authState.currentSession, isNotNull);
  });

  testWidgets('confirm starts once, blocks dismissal, and waits for local auth to clear', (tester) async {
    var confirmations = 0;
    bool? result;
    final authState = FakeAppAuthState(AuthSessionDto.fixture());
    await tester.pumpWidget(
      TestApp.screen(
        providerOverrides: [
          appAuthStateProvider.overrideWith(() => authState),
          appStorageStateProvider.overrideWith(() => FixedAppStorageState(hasSeenSwipeFeedHint: true)),
        ],
        child: LogoutWarningSheetTestHost(
          onConfirmed: () async => confirmations++,
          onResult: (didLogout) => result = didLogout,
        ),
      ),
    );
    await tester.tap(find.byKey(LogoutWarningSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('logout_warning_sheet_logout_button')));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(find.byType(LogoutWarningSheet), findsOneWidget);
    expect(
      tester.widget<MateoButton>(find.byKey(const ValueKey('logout_warning_sheet_logout_button'))).isLoading,
      isTrue,
    );
    expect(confirmations, 1);
    await tester.tap(find.descendant(of: find.byType(MateoSheetViewHeader), matching: find.byType(MateoButton)));
    await tester.tap(find.byKey(const ValueKey('logout_warning_sheet_back_button')));
    await tester.tap(find.byKey(const ValueKey('logout_warning_sheet_logout_button')));
    await tester.pump();
    expect(find.byType(LogoutWarningSheet), findsOneWidget);
    expect(confirmations, 1);

    authState.currentSession = null;
    await tester.pumpAndSettle();
    expect(find.byType(LogoutWarningSheet), findsNothing);
    expect(result, isTrue);
  });
}
