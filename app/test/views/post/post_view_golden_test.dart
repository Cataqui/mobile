import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/views/post/post_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../utils/test_app.dart';
import 'post_test_state.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () => group('PostView Golden Tests', () {
      goldenTest(
        'when the empty composer is focused, it should show static details and disabled publishing above the keyboard',
        fileName: 'post_view_empty',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        builder: PostViewGoldenTestHelpers.buildPostView,
      );

      goldenTest(
        'when typing a long description, it should keep editing usable while details remain in scroll content',
        fileName: 'post_view_long_description',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await tester.pumpAndSettle();
          await tester.enterText(
            find.byKey(const ValueKey('post_description_input')),
            List.generate(16, (index) => 'Linha ${index + 1} do trampo').join('\n'),
          );
          await tester.pumpAndSettle();
          return null;
        },
        builder: PostViewGoldenTestHelpers.buildPostView,
      );

      AlchemistConfig.runWithConfig(
        config: AlchemistConfig.current().copyWith(
          ciGoldensConfig: AlchemistConfig.current().ciGoldensConfig.copyWith(diffThreshold: 0),
        ),
        run: () {
          for (final scenario in [
            (name: 'new_line', description: 'a new line is entered', text: 'Primeira linha\nNova linha com gypqj'),
            (
              name: 'line_wrap',
              description: 'typing wraps onto a new line',
              text: 'Preciso de ajuda para descarregar as caixas do caminhão hoje',
            ),
          ]) {
            goldenTest(
              'when ${scenario.description}, it should show the entire line immediately',
              fileName: 'post_view_${scenario.name}_first_frame',
              constraints: const BoxConstraints.tightFor(width: 390, height: 844),
              whilePerforming: (tester) async {
                await tester.pumpAndSettle();
                await tester.enterText(find.byKey(const ValueKey('post_description_input')), 'Primeira linha');
                await tester.pumpAndSettle();
                await tester.enterText(find.byKey(const ValueKey('post_description_input')), scenario.text);
                await tester.pump();
                return () async {
                  await tester.pumpAndSettle();
                };
              },
              builder: () => PostViewGoldenTestHelpers.buildPostView(disableAnimations: false),
            );
          }
        },
      );

      goldenTest(
        'when a location is selected, its concise name should replace the default location chip label',
        fileName: 'post_view_selected_location',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        builder: PostViewGoldenTestHelpers.buildPostViewWithSelectedLocation,
      );

      goldenTest(
        'when a contact is selected, its formatted identifier should replace the default contact chip label',
        fileName: 'post_view_selected_contact',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        builder: PostViewGoldenTestHelpers.buildPostViewWithSelectedContact,
      );
    }),
  );
}

abstract final class PostViewGoldenTestHelpers {
  static Widget buildPostViewWithSelectedLocation() {
    return buildPostView(initialPostData: const PostData(locationTitle: 'Avenida Paulista'));
  }

  static Widget buildPostViewWithSelectedContact() {
    return buildPostView(
      initialPostData: const PostData(contact: (contactMethod: JobContactMethod.whatsapp, identifier: 'Ventairy.Dev')),
    );
  }

  static Widget buildPostView({PostData initialPostData = const PostData(), bool disableAnimations = true}) {
    final i18n = AppLocale.ptBr.buildSync();

    return SizedBox(
      width: 390,
      height: 844,
      child: TestApp.screen(
        mediaQueryData: MediaQueryData(
          size: const Size(390, 844),
          viewInsets: const EdgeInsets.only(bottom: 300),
          disableAnimations: disableAnimations,
        ),
        providerOverrides: [
          translationProvider.overrideWithValue(i18n),
          postStateProvider.overrideWith(() => PostTestState(initialData: initialPostData)),
        ],
        child: const PostView(),
      ),
    );
  }
}
