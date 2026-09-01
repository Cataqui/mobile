import 'package:alchemist/alchemist.dart';
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

      goldenTest(
        'when a location is selected, its concise name should replace the default location chip label',
        fileName: 'post_view_selected_location',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        builder: PostViewGoldenTestHelpers.buildPostViewWithSelectedLocation,
      );
    }),
  );
}

abstract final class PostViewGoldenTestHelpers {
  static Widget buildPostViewWithSelectedLocation() {
    return buildPostView(initialPostData: const PostData(locationTitle: 'Avenida Paulista'));
  }

  static Widget buildPostView({PostData initialPostData = const PostData()}) {
    final i18n = AppLocale.ptBr.buildSync();

    return SizedBox(
      width: 390,
      height: 844,
      child: TestApp.screen(
        mediaQueryData: const MediaQueryData(
          size: Size(390, 844),
          viewInsets: EdgeInsets.only(bottom: 300),
          disableAnimations: true,
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
