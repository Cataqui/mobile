import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_button/whatsapp_connection_button.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_sheet/whatsapp_connection_sheet.dart';
import 'package:cataqui_app/widgets/whatsapp_connection_sheet/whatsapp_connection_sheet_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../mocks.dart';
import '../../utils/test_app.dart';
import '../whatsapp_connection_button/whatsapp_connection_button_test_helpers.dart';
import 'whatsapp_connection_sheet_test_host.dart';

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
    WhatsappConnectionButtonTestHelpers.stubSuccessfulRegistration(authRepository: authRepository, whatsapp: whatsapp);
    WhatsappConnectionButtonTestHelpers.stubSuccessfulExchange(authRepository: authRepository);
  });

  Future<void> pumpHost(WidgetTester tester, {GlobalKey<NavigatorState>? navigatorKey}) async {
    await tester.pumpWidget(
      TestApp(
        mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
        navigatorKey: navigatorKey,
        providerOverrides: [
          translationProvider.overrideWithValue(i18n),
          authRepositoryProvider.overrideWithValue(authRepository),
          whatsappProvider(identifier: WhatsappConnectionButtonTestHelpers.codeReceiver).overrideWithValue(whatsapp),
        ],
        child: WhatsappConnectionSheetTestHost(onShown: (result) => sheetResult = result),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.byKey(WhatsappConnectionSheetTestHost.openButtonKey));
    await tester.pumpAndSettle();
  }

  group('WhatsappConnectionSheet', () {
    testWidgets(
      'when opened, it should show the localized connection message, padlock, and WhatsApp connection action',
      (tester) async {
        await pumpHost(tester);

        await openSheet(tester);
        final keysImage = tester.widget<Image>(
          find.descendant(of: find.byType(WhatsappConnectionSheet), matching: find.byType(Image)),
        );
        final keysImageProvider = keysImage.image;
        final keysAssetImage = keysImageProvider is ResizeImage ? keysImageProvider.imageProvider : keysImageProvider;

        expect(
          (
            title: tester.widget<Text>(find.byKey(WhatsappConnectionSheet.titleKey)).data,
            keysAssetName: (keysAssetImage as AssetImage).assetName,
            connectionButtonCount: find.byType(WhatsappConnectionButton).evaluate().length,
          ),
          (
            title: 'Conecte seu WhatsApp pra continuar',
            keysAssetName: 'assets/icons/padlock.webp',
            connectionButtonCount: 1,
          ),
        );
      },
    );

    testWidgets('when connection has not started, tapping outside should close the sheet and complete with false', (
      tester,
    ) async {
      await pumpHost(tester);
      await openSheet(tester);

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();

      expect(await sheetResult, isFalse);
    });

    testWidgets('when connection is active, the close button should dismiss the sheet', (tester) async {
      await pumpHost(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pump();

      await tester.tap(find.descendant(of: find.byType(MateoSheetViewHeader), matching: find.byType(MateoButton)));
      await tester.pumpAndSettle();

      expect(await sheetResult, isFalse);
    });

    testWidgets('when the phone back action is used during connection, it should close and complete with false', (
      tester,
    ) async {
      await pumpHost(tester);
      await openSheet(tester);
      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pump();

      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(await sheetResult, isFalse);
    });

    testWidgets('when WhatsApp connection succeeds, it should close and complete with true', (tester) async {
      await pumpHost(tester);
      await openSheet(tester);

      await tester.tap(find.byKey(WhatsappConnectionButtonTestHelpers.buttonKey));
      await tester.pump();
      await WhatsappConnectionButtonTestHelpers.resumeApp(tester: tester);
      await tester.pumpAndSettle();

      expect(await sheetResult, isTrue);
    });
  });

  group('WhatsappConnectionSheetController', () {
    testWidgets(
      'when a keyboard inset is present, it should keep focus away during a cancelled drag and restore it after dismissal',
      (tester) async {
        final navigatorKey = GlobalKey<NavigatorState>();
        final focusNode = FocusNode();
        addTearDown(focusNode.dispose);
        addTearDown(tester.view.reset);
        tester.view
          ..devicePixelRatio = 1
          ..physicalSize = const Size(390, 844)
          ..viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpWidget(
          TestApp(
            navigatorKey: navigatorKey,
            providerOverrides: [
              translationProvider.overrideWithValue(i18n),
              authRepositoryProvider.overrideWithValue(authRepository),
              whatsappProvider(
                identifier: WhatsappConnectionButtonTestHelpers.codeReceiver,
              ).overrideWithValue(whatsapp),
            ],
            child: TextField(focusNode: focusNode, autofocus: true),
          ),
        );
        await tester.pumpAndSettle();
        final controller = WhatsappConnectionSheetController(navigatorKey);

        final presentation = controller.show();
        await tester.pumpAndSettle();
        final fieldHasFocusWhileSheetIsOpen = focusNode.hasFocus;
        final sheetRectWhileInsetIsPresent = tester.getRect(find.byKey(const Key('whatsapp_connection_sheet_surface')));
        final drag = await tester.startGesture(tester.getCenter(find.byType(WhatsappConnectionSheet)));
        await drag.moveBy(const Offset(0, 40));
        await tester.pump();
        final fieldHasFocusDuringDrag = focusNode.hasFocus;
        await drag.cancel();
        await tester.pumpAndSettle();
        final fieldHasFocusAfterCancelledDrag = focusNode.hasFocus;
        Navigator.of(tester.element(find.byType(WhatsappConnectionSheet))).pop();
        await tester.pumpAndSettle();

        expect(
          (
            fieldHasFocusWhileSheetIsOpen: fieldHasFocusWhileSheetIsOpen,
            fieldHasFocusDuringDrag: fieldHasFocusDuringDrag,
            fieldHasFocusAfterCancelledDrag: fieldHasFocusAfterCancelledDrag,
            fieldHasFocusAfterDismissal: focusNode.hasFocus,
            sheetBottomWhileInsetIsPresent: sheetRectWhileInsetIsPresent.bottom,
            result: await presentation,
          ),
          (
            fieldHasFocusWhileSheetIsOpen: false,
            fieldHasFocusDuringDrag: false,
            fieldHasFocusAfterCancelledDrag: false,
            fieldHasFocusAfterDismissal: true,
            sheetBottomWhileInsetIsPresent: 832,
            result: false,
          ),
        );
      },
    );

    testWidgets('when presentation is already active, concurrent callers should share one sheet and result', (
      tester,
    ) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      await pumpHost(tester, navigatorKey: navigatorKey);
      final controller = WhatsappConnectionSheetController(navigatorKey);

      final firstPresentation = controller.show();
      final secondPresentation = controller.show();
      await tester.pumpAndSettle();
      final visibleSheetCount = find.byType(WhatsappConnectionSheet).evaluate().length;
      Navigator.of(tester.element(find.byType(WhatsappConnectionSheet))).pop();
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
