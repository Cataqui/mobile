import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/add_contact/add_contact_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

import '../../utils/test_app.dart';

void main() {
  final i18n = AppLocale.ptBr.buildSync();

  testWidgets('Save is available only while the phone number is valid', (tester) async {
    await tester.pumpWidget(const TestApp.screen(child: AddContactView()));
    await tester.pumpAndSettle();

    final input = tester.widget<EditableText>(find.byType(EditableText));
    final saveButton = find.byKey(const ValueKey('add_contact_save_button'));
    expect(input.focusNode.hasFocus, isTrue);
    expect(input.keyboardType, TextInputType.phone);
    expect(find.byKey(const ValueKey('add_contact_title')), findsOneWidget);
    expect(tester.widget<MateoButton>(saveButton).onPressed, isNull);

    await tester.tap(saveButton);
    await tester.pump();
    expect(find.byType(AddContactView), findsOneWidget);

    await tester.enterText(find.byType(EditableText), '119');
    await tester.pump();
    expect(tester.widget<MateoButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byType(EditableText), '+19999999999');
    await tester.pump();
    expect(tester.widget<MateoButton>(saveButton).onPressed, isNull);

    await tester.enterText(find.byType(EditableText), '+5511912345678');
    await tester.pump();
    expect(tester.widget<MateoButton>(saveButton).onPressed, isNotNull);

    await tester.enterText(find.byType(EditableText), '119');
    await tester.pump();
    expect(tester.widget<MateoButton>(saveButton).onPressed, isNull);
  });

  testWidgets('when the country selector is tapped, Mateo opens its picker', (tester) async {
    await tester.pumpWidget(const TestApp.screen(child: AddContactView()));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(MateoCountryFlag));
    await tester.pumpAndSettle();
    expect(find.byType(MateoSheetView), findsOneWidget);
  });

  testWidgets('WhatsApp logo wraps with the WhatsApp title word', (tester) async {
    tester.view
      ..physicalSize = const Size(260, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const TestApp.screen(child: AddContactView()));
    await tester.pumpAndSettle();
    final title = find.byKey(const ValueKey('add_contact_title'));
    final logo = find.byKey(const ValueKey('add_contact_whatsapp_logo'));
    final titleParagraph = tester.renderObject<RenderParagraph>(title);
    final whatsappStart = i18n.addContact.title.lastIndexOf('WhatsApp');
    final whatsappBox = titleParagraph
        .getBoxesForSelection(TextSelection(baseOffset: whatsappStart, extentOffset: i18n.addContact.title.length))
        .single
        .toRect()
        .shift(tester.getTopLeft(title));
    final logoRect = tester.getRect(logo);

    expect(whatsappBox.top, greaterThan(tester.getTopLeft(title).dy));
    expect(logoRect.bottom, greaterThan(whatsappBox.top));
    expect(logoRect.top, lessThan(whatsappBox.bottom));
  });

  for (final bottomInset in [0.0, 300.0]) {
    testWidgets('Save stays above a $bottomInset keyboard inset on a narrow screen with large text', (tester) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        TestApp.screen(
          mediaQueryData: MediaQueryData(
            size: const Size(320, 640),
            viewInsets: EdgeInsets.only(bottom: bottomInset),
            textScaler: const TextScaler.linear(1.5),
          ),
          child: const AddContactView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(
        tester.getBottomLeft(find.byKey(const ValueKey('add_contact_save_button'))).dy,
        lessThanOrEqualTo(640 - bottomInset),
      );
      expect(find.text(i18n.addContact.saveButtonTitle), findsOneWidget);
    });
  }
}
