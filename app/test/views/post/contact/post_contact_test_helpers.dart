import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../../../utils/test_app.dart';
import '../post_test_state.dart';

abstract final class PostContactTestHelpers {
  static const whatsappUsernameContact = SavedContactDto(
    contactId: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa',
    contactMethod: JobContactMethod.whatsapp,
    identifier: 'Ventairy.Dev',
  );
  static const phoneContact = SavedContactDto(
    contactId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
    contactMethod: JobContactMethod.phoneCall,
    identifier: '+1 (202) 555-0123',
  );

  static Future<void> open(
    WidgetTester tester, {
    required MockUserRepository userRepository,
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
    bool settle = true,
  }) async {
    await pump(
      tester,
      userRepository: userRepository,
      initialPostData: initialPostData,
      disableAnimations: disableAnimations,
    );
    await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
    await tester.pump();
    if (settle) await tester.pumpAndSettle();
  }

  static Future<void> pump(
    WidgetTester tester, {
    required MockUserRepository userRepository,
    PostData initialPostData = const PostData(),
    bool disableAnimations = true,
  }) async {
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = const Size(390, 844)
      ..padding = const FakeViewPadding(top: 47, bottom: 34)
      ..viewPadding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      TestApp.screen(
        mediaQueryData: MediaQueryData(
          size: const Size(390, 844),
          devicePixelRatio: 1,
          padding: const EdgeInsets.only(top: 47, bottom: 34),
          viewPadding: const EdgeInsets.only(top: 47, bottom: 34),
          textScaler: TextScaler.noScaling,
          disableAnimations: disableAnimations,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          userRepositoryProvider.overrideWithValue(userRepository),
          postStateProvider.overrideWith(() => PostTestState(initialData: initialPostData)),
        ],
        child: const PostView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  static void stubContacts(
    MockUserRepository userRepository, {
    List<SavedContactDto> contacts = const [whatsappUsernameContact, phoneContact],
  }) {
    when(userRepository.getContacts).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: contacts));
  }
}
