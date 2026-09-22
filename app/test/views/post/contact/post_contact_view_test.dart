import 'dart:async';

import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/contact/post_contact_view.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../../mocks.dart';
import 'post_contact_test_helpers.dart';

void main() {
  late MockUserRepository userRepository;
  late Translations i18n;

  setUpAll(() {
    i18n = AppLocale.ptBr.buildSync();
  });

  setUp(() {
    userRepository = MockUserRepository();
    PostContactTestHelpers.stubContacts(userRepository);
  });

  testWidgets('when the contact chip is tapped, it should push the Mateo contact sheet', (tester) async {
    await PostContactTestHelpers.open(tester, userRepository: userRepository);
    final header = find.byType(MateoSheetViewHeader);
    final footer = find.byType(MateoSheetViewFooter);
    final surface = tester.widget<MateoSheetViewSurface>(find.byKey(const ValueKey('post_contact_sheet_surface')));

    expect(
      (
        view: find.byType(PostContactView).evaluate().length,
        sheet: find.byKey(const ValueKey('post_contact_sheet_surface')).evaluate().length,
        handleInHeader: find
            .descendant(of: header, matching: find.byType(InteractiveSwipeDismissHandle))
            .evaluate()
            .length,
        addActionInFooter: find
            .descendant(of: footer, matching: find.byKey(const ValueKey('post_contact_add_button')))
            .evaluate()
            .length,
        edgeEffect: surface.edgeEffect,
      ),
      (
        view: 1,
        sheet: 1,
        handleInHeader: 1,
        addActionInFooter: 1,
        edgeEffect: MateoEdgeEffect.fade(at: const [.bottom]),
      ),
    );
  });

  for (final (contactCount, screenHeight) in [(1, 844.0), (2, 844.0), (20, 844.0), (20, 700.0)]) {
    testWidgets(
      'when $contactCount contacts are saved on a $screenHeight tall screen, it should use the requested height',
      (tester) async {
        PostContactTestHelpers.stubContacts(
          userRepository,
          contacts: List.generate(
            contactCount,
            (index) => PostContactTestHelpers.phoneContact.copyWith(contactId: 'contact_$index'),
          ),
        );
        await PostContactTestHelpers.open(tester, userRepository: userRepository, screenSize: Size(390, screenHeight));
        final surface = find.byKey(const ValueKey('post_contact_sheet_surface'));
        final list = find.byKey(const ValueKey('post_contact_options'));
        final scrollController = tester.widget<ListView>(list).controller!;

        if (contactCount < 3) {
          expect(tester.getSize(surface).height, 380);
          expect(scrollController.position.maxScrollExtent, 0);
          return;
        }

        expect(tester.getSize(surface).height, 380);
        final add = find.byKey(const ValueKey('post_contact_add_button'));
        final buttonPosition = tester.getTopLeft(add);
        await tester.drag(list, const Offset(0, -250));
        await tester.pumpAndSettle();
        expect(scrollController.offset, greaterThan(0));
        expect(tester.getTopLeft(add), buttonPosition);
      },
    );
  }

  testWidgets('when contacts are loading, it should show skeleton rows and localized semantics', (tester) async {
    when(userRepository.getContacts).thenAnswer((_) => Completer<ApiEnvelopeDto<List<SavedContactDto>>>().future);

    await PostContactTestHelpers.open(tester, userRepository: userRepository, settle: false);

    final skeleton = tester.widget<Skeleton>(find.byKey(const ValueKey('post_contact_skeleton')));
    expect(
      (
        semantics: skeleton.semanticsLabel,
        rows: find.byKey(const ValueKey('post_contact_skeleton_row_0')).evaluate().length,
      ),
      (semantics: i18n.post.contact.loadingSemanticLabel, rows: 1),
    );
  });

  testWidgets('when loading finishes with one contact, it should keep the sheet and add button in place', (
    tester,
  ) async {
    final contactsCompleter = Completer<ApiEnvelopeDto<List<SavedContactDto>>>();
    when(userRepository.getContacts).thenAnswer((_) => contactsCompleter.future);
    await PostContactTestHelpers.open(tester, userRepository: userRepository, settle: false);
    final surface = find.byKey(const ValueKey('post_contact_sheet_surface'));
    final add = find.byKey(const ValueKey('post_contact_add_button'));
    final loadingSize = tester.getSize(surface);
    final loadingButtonPosition = tester.getTopLeft(add);
    expect(loadingSize.height, 380);

    contactsCompleter.complete(ApiEnvelopeDto.fixture(data: [PostContactTestHelpers.phoneContact]));
    await tester.pumpAndSettle();

    expect(tester.getSize(surface), loadingSize);
    expect(tester.getTopLeft(add), loadingButtonPosition);
  });

  testWidgets('when contacts finish loading, it should show formatted API-order rows', (tester) async {
    final contactsCompleter = Completer<ApiEnvelopeDto<List<SavedContactDto>>>();
    when(userRepository.getContacts).thenAnswer((_) => contactsCompleter.future);
    await PostContactTestHelpers.open(tester, userRepository: userRepository, disableAnimations: false, settle: false);

    contactsCompleter.complete(
      ApiEnvelopeDto.fixture(
        data: [PostContactTestHelpers.phoneContact, PostContactTestHelpers.whatsappUsernameContact],
      ),
    );
    await tester.pumpAndSettle();
    final phone = find.text('+1 202-555-0123');
    final username = find.text('@ventairy.dev');

    expect(
      (
        phone: phone.evaluate().length,
        username: username.evaluate().length,
        apiOrder: tester.getTopLeft(phone).dy < tester.getTopLeft(username).dy,
      ),
      (phone: 1, username: 1, apiOrder: true),
    );
  });

  testWidgets('when a contact is selected, it should store its original value, close, and update the chip', (
    tester,
  ) async {
    await PostContactTestHelpers.open(tester, userRepository: userRepository);
    final container = ProviderScope.containerOf(tester.element(find.byType(PostContactView)));

    await tester.tap(find.byKey(const ValueKey('post_contact_option_aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa')));
    await tester.pumpAndSettle();
    final contactChip = find.byKey(const ValueKey('post_contact_chip'));
    final whatsappIconType = const MateoIcon(.whatsapp).runtimeType;

    expect(
      (
        contact: container.read(postStateProvider).contact,
        sheetCount: find.byType(PostContactView).evaluate().length,
        chipTextCount: find.text('@ventairy.dev').evaluate().length,
        whatsappIconCount: find
            .descendant(
              of: contactChip,
              matching: find.byWidgetPredicate((widget) => widget.runtimeType == whatsappIconType),
            )
            .evaluate()
            .length,
      ),
      (
        contact: (contactMethod: JobContactMethod.whatsapp, identifier: 'Ventairy.Dev'),
        sheetCount: 0,
        chipTextCount: 1,
        whatsappIconCount: 1,
      ),
    );
  });

  testWidgets('when no contacts are saved, it should show the empty state above the add action', (tester) async {
    PostContactTestHelpers.stubContacts(userRepository, contacts: const []);

    await PostContactTestHelpers.open(tester, userRepository: userRepository);
    expect(tester.getSize(find.byKey(const ValueKey('post_contact_sheet_surface'))).height, 380);
    final empty = find.text(i18n.post.contact.empty);
    final add = find.byKey(const ValueKey('post_contact_add_button'));

    expect(
      (emptyCount: empty.evaluate().length, aboveButton: tester.getBottomLeft(empty).dy < tester.getTopLeft(add).dy),
      (emptyCount: 1, aboveButton: true),
    );
  });

  testWidgets('when loading contacts fails, it should show the localized error', (tester) async {
    when(userRepository.getContacts).thenThrow(StateError('load failed'));

    await PostContactTestHelpers.open(tester, userRepository: userRepository);

    expect(find.text(i18n.post.contact.error), findsOneWidget);
    expect(tester.getSize(find.byKey(const ValueKey('post_contact_sheet_surface'))).height, 380);
  });

  testWidgets('when the header handle is dragged, it should dismiss the contact sheet', (tester) async {
    await PostContactTestHelpers.open(tester, userRepository: userRepository);

    await tester.drag(find.byType(InteractiveSwipeDismissHandle), const Offset(0, 300));
    await tester.pumpAndSettle();

    expect(find.byType(PostContactView), findsNothing);
  });

  testWidgets('when system back is invoked, it should dismiss the contact sheet', (tester) async {
    await PostContactTestHelpers.open(tester, userRepository: userRepository);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.byType(PostContactView), findsNothing);
  });

  testWidgets('when the sheet is closed and reopened, it should start a fresh contact request', (tester) async {
    await PostContactTestHelpers.open(tester, userRepository: userRepository);
    await tester.drag(find.byType(InteractiveSwipeDismissHandle), const Offset(0, 300));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
    await tester.pumpAndSettle();

    verify(userRepository.getContacts).called(2);
  });
}
