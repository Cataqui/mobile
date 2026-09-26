import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/me_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class CurrentUserDisplayIdentifier extends ConsumerWidget {
  const CurrentUserDisplayIdentifier({super.key});

  static const _height = 22.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = MateoTheme.of(context).colorScheme;
    final identifierStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: colorScheme.text.primary);
    final loadingLabel = ref.watch(translationProvider).me.loadingSemanticLabel;

    return ref
        .watch(meStateProvider)
        .when(
          data: (profile) => profile == null
              ? const SizedBox(height: _height)
              : Text(
                  profile.displayIdentifier,
                  key: const ValueKey('me_identifier'),
                  textAlign: TextAlign.center,
                  style: identifierStyle,
                ),
          error: (_, _) => const SizedBox(height: _height),
          loading: () => Center(
            child: Skeleton(
              key: const ValueKey('me_identifier_skeleton'),
              semanticsLabel: loadingLabel,
              style: SkeletonStyle(
                color: colorScheme.skeleton.bone,
                effect: const SkeletonFadeEffect(),
                shape: const MateoRoundedShapeBorder.capsule(),
              ),
              child: Text(loadingLabel, style: identifierStyle),
            ),
          ),
        );
  }
}
