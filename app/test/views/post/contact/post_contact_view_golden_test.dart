import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
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
import 'post_contact_test_helpers.dart';

void main() {
  late MockUserRepository userRepository;

  setUp(() {
    userRepository = MockUserRepository();
    PostContactTestHelpers.stubContacts(userRepository);
  });

  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when saved contacts load, it should show every contact and the anchored add action',
        fileName: 'post_contact_loaded',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: _PostContactViewGoldenTestHelpers.openSheet,
        builder: () => _PostContactViewGoldenTestHelpers.buildPostView(userRepository),
      );

      goldenTest(
        'when contacts are loading, it should show representative skeleton rows',
        fileName: 'post_contact_loading',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          when(userRepository.getContacts).thenAnswer((_) => Completer<ApiEnvelopeDto<List<SavedContactDto>>>().future);
          await tester.pumpAndSettle();
          await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
          for (var frame = 0; frame < 80; frame++) {
            await tester.pump(const Duration(milliseconds: 16));
          }
          tester.binding.renderViews.single.markNeedsPaint();
          await tester.pump();
          return null;
        },
        builder: () => _PostContactViewGoldenTestHelpers.buildPostView(userRepository),
      );

      goldenTest(
        'when no contacts are saved, it should show the empty state and anchored add action',
        fileName: 'post_contact_empty',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          PostContactTestHelpers.stubContacts(userRepository, contacts: const []);
          return _PostContactViewGoldenTestHelpers.openSheet(tester);
        },
        builder: () => _PostContactViewGoldenTestHelpers.buildPostView(userRepository),
      );
    },
  );
}

abstract final class _PostContactViewGoldenTestHelpers {
  static Future<Future<void> Function()?> openSheet(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('post_contact_chip')));
    for (var frame = 0; frame < 80; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.pumpAndSettle();
    tester.binding.renderViews.single.markNeedsPaint();
    await tester.pump();
    return null;
  }

  static Widget buildPostView(MockUserRepository userRepository) {
    return SizedBox(
      width: 390,
      height: 844,
      child: TestApp.screen(
        mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
        providerOverrides: [
          translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
          userRepositoryProvider.overrideWithValue(userRepository),
          postStateProvider.overrideWith(() => PostTestState(initialData: const PostData())),
        ],
        child: const PostView(),
      ),
    );
  }
}
