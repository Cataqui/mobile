import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/svg.g.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/me/my_posts_carousel.dart';
import 'package:cataqui_app/views/me/user_avatar_morph_target.dart';
import 'package:cataqui_app/views/me/widgets/current_user_display_identifier.dart';
import 'package:cataqui_app/widgets/logout_warning_sheet/logout_warning_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class MeView extends ConsumerWidget {
  const MeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);
    final colorScheme = MateoTheme.of(context).colorScheme;
    const surfacePadding = EdgeInsets.fromLTRB(22, 24, 22, 24);

    return LayoutBuilder(
      builder: (context, constraints) => MateoView(
        key: const ValueKey('me_view'),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        header: MateoViewHeader(
          leading: MateoButton(
            key: const ValueKey('me_close_button'),
            onPressed: () => Navigator.of(context).pop(),
            presentation: .icon(
              variant: .primary.base,
              elevation: 1,
              semanticLabel: i18n.me.closeButtonSemanticLabel,
              icon: const MateoIcon(.cross),
            ),
          ),
          trailing: MateoButton(
            key: const ValueKey('me_logout_button'),
            onPressed: () => unawaited(_showLogout(context, ref)),
            presentation: .icon(
              variant: .primary.base,
              elevation: 1,
              semanticLabel: i18n.me.logoutButtonSemanticLabel,
              icon: const MateoIcon(.logout),
            ),
          ),
        ),
        surface: MateoViewSurface.scrollable(
          color: colorScheme.background,
          padding: surfacePadding,
          edgeEffect: .fade(at: [.top]),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Morph(
                  targets: [ref.watch(userAvatarMorphTargetProvider)],
                  child: $Svg.defaultUserProfilePicture(
                    key: const ValueKey('me_avatar'),
                    height: 100,
                    color1: MateoTheme.of(context).palette.neutral[2],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const CurrentUserDisplayIdentifier(),
              const SizedBox(height: 62),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  crossAxisAlignment: .center,
                  mainAxisAlignment: .start,
                  children: [
                    MateoIcon(.socialMediaPost, size: 26, color: colorScheme.text.tertiary),
                    const SizedBox(width: 4),
                    Text(
                      i18n.me.myPosts.title,
                      key: const ValueKey('me_posts_heading'),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.text.tertiary),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              MyPostsCarousel(
                viewportWidth: constraints.maxWidth - surfacePadding.horizontal,
                rightOverflow: surfacePadding.right,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLogout(BuildContext context, WidgetRef ref) async {
    final meRoute = ModalRoute.of(context);
    final appAuthState = ref.read(appAuthStateProvider.notifier);
    final appToast = ref.read(appToastProvider);
    final successMessage = ref.read(translationProvider).logoutWarningSheet.success;
    final rootNavigator = ref.read(rootNavigatorKeyProvider).currentState;

    final didLogout = await LogoutWarningSheet.show(
      context: context,
      onConfirmed: () async {
        try {
          await appAuthState.logoutCurrentSession();
        } on Object {
          // Local logout has already completed; remote revocation has no UI feedback.
        }
      },
    );
    if (!didLogout || !context.mounted) return;

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) {
      await ref
          .read(appRouterProvider.notifier)
          .go(
            context,
            FeedRoute(
              $extra: (toast: MateoToast(message: successMessage, status: .success)),
            ),
          );
      return;
    }

    navigator.pop();
    await meRoute?.completed;

    final toastContext = rootNavigator?.overlay?.context;
    if (toastContext == null || !toastContext.mounted) return;
    appToast.showSuccess(toastContext, message: successMessage);
  }
}
