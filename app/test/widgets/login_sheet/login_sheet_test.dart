import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet.dart';
import 'package:cataqui_app/widgets/login_sheet/login_sheet_controller.dart';
import 'package:cataqui_app/widgets/whatsapp_login_button/whatsapp_login_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import '../whatsapp_login_button/whatsapp_login_button_test_helpers.dart';
import 'login_sheet_test_host.dart';

void main() {
  late MockAuthRepository authRepository;
  late MockWhatsapp whatsapp;
  late Translations i18n;
  late Future<bool>? sheetResult;

  setUp(() {
    authRepository = MockAuthRepository();
    whatsapp = MockWhatsapp();
    i18n = AppLocale.ptBr.buildSync();
    sheetResult = null;
    WhatsappLoginButtonTestHelpers.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    WhatsappLoginButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
  });

  Future<void> pumpHost(WidgetTester tester, {GlobalKey<NavigatorState>? navigatorKey}) async {
    await tester.pumpWidget(
      TestApp(
        mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
        navigatorKey: navigatorKey,
        providerOverrides: [
          translationProvider.overrideWithValue(i18n),
          authRepositoryProvider.overrideWithValue(authRepository),
          whatsappProvider.overrideWithValue(whatsapp),
        ],
        child: LoginSheetTestHost(onShown: (result) => sheetResult = result),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(LoginSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();
  }

  group('LoginSheet', () {
    testWidgets('when opened, it should show the localized account message, keys, and WhatsApp login action', (
      tester,
    ) async {
      await pumpHost(tester);

      await openSheet(tester);
      final keysImage = tester.widget<Image>(
        find.descendant(of: find.byType(LoginSheet), matching: find.byType(Image)),
      );
      final keysImageProvider = keysImage.image;
      final keysAssetImage = keysImageProvider is ResizeImage ? keysImageProvider.imageProvider : keysImageProvider;

      expect(
        (
          title: tester.widget<Text>(find.byKey(LoginSheet.titleKey)).data,
          subtitle: tester.widget<Text>(find.byKey(LoginSheet.subtitleKey)).data,
          keysAssetName: (keysAssetImage as AssetImage).assetName,
          loginButtonCount: find.byType(WhatsappLoginButton).evaluate().length,
        ),
        (
          title: i18n.loginSheet.title,
          subtitle: i18n.loginSheet.subtitle,
          keysAssetName: 'assets/illustrations/keys.webp',
          loginButtonCount: 1,
        ),
      );
    });

    testWidgets('when login has not started, tapping outside should close the sheet and complete with false', (
      tester,
    ) async {
      await pumpHost(tester);
      await openSheet(tester);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(await sheetResult, isFalse);
    });

    testWidgets(
      'when login is active, tapping outside and dragging should keep the sheet open until the close button is tapped',
      (tester) async {
        await pumpHost(tester);
        await openSheet(tester);
        await tester.tap(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));
        await tester.pump();

        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        final isVisibleAfterOutsideTap = find.byType(LoginSheet).evaluate().isNotEmpty;
        await tester.drag(find.byKey(const Key('mateo_bottom_sheet_surface')), const Offset(0, 500));
        await tester.pump(const Duration(seconds: 1));
        final isVisibleAfterDrag = find.byType(LoginSheet).evaluate().isNotEmpty;
        await tester.tap(find.byKey(const Key('mateo_bottom_sheet_close_button')));
        await tester.pumpAndSettle();

        expect(
          (
            isVisibleAfterOutsideTap: isVisibleAfterOutsideTap,
            isVisibleAfterDrag: isVisibleAfterDrag,
            result: await sheetResult,
          ),
          (isVisibleAfterOutsideTap: true, isVisibleAfterDrag: true, result: false),
        );
      },
    );

    testWidgets('when the phone back action is used during login, it should close and complete with false', (
      tester,
    ) async {
      await pumpHost(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await sheetResult, isFalse);
    });

    testWidgets('when WhatsApp login succeeds, it should close and complete with true', (tester) async {
      await pumpHost(tester);
      await openSheet(tester);

      await tester.tap(find.byKey(WhatsappLoginButtonTestHelpers.buttonKey));
      await tester.pump();
      await WhatsappLoginButtonTestHelpers.resumeApp(tester: tester);
      await tester.pumpAndSettle();

      expect(await sheetResult, isTrue);
    });
  });

  group('LoginSheetController', () {
    testWidgets('when presentation is already active, concurrent callers should share one sheet and result', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await pumpHost(tester, navigatorKey: navigatorKey);
      final controller = LoginSheetController(navigatorKey);

      final firstPresentation = controller.show();
      final secondPresentation = controller.show();
      await tester.pumpAndSettle();
      final visibleSheetCount = find.byType(LoginSheet).evaluate().length;
      Navigator.of(tester.element(find.byType(LoginSheet))).pop();
      await tester.pumpAndSettle();
      final results = await Future.wait([firstPresentation, secondPresentation]);

      expect(
        (
          sameFuture: identical(firstPresentation, secondPresentation),
          visibleSheetCount: visibleSheetCount,
          firstResult: results.first,
          secondResult: results.last,
        ),
        (sameFuture: true, visibleSheetCount: 1, firstResult: false, secondResult: false),
      );
    });
  });
}
