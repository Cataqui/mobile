import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/post/enums/post_morph_tag.dart';
import 'package:cataqui_app/views/post/post_details_input/post_details_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class PostView extends ConsumerWidget {
  const PostView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final i18n = ref.watch(translationProvider);

    return MateoScrollableView(
      key: const ValueKey('post_view'),
      backgroundColor: context.mateo.colorScheme.background,
      edgeFade: (top: const MateoEdgeFadeStyle(), bottom: null),
      header: MateoViewHeader(
        key: const ValueKey('post_header'),
        centerTitle: false,
        title: Text(i18n.post.title),
        leading: Morph(
          tag: PostMorphTag.closeButton,
          curve: Curves.decelerate,
          watchDestination: true,
          switchThreshold: 0.2,
          child: MateoFloatingActionButton(
            key: const ValueKey('post_close_button'),
            semanticLabel: i18n.post.closeButtonSemanticLabel,
            onPressed: () async {
              final navigator = Navigator.of(context);

              if (navigator.canPop()) {
                navigator.pop();
                return;
              }

              await ref.read(appRouterProvider.notifier).go(context, const FeedRoute());
            },
            iconSize: 16,
            size: 50,
            iconBuilder: (state) {
              return MateoIcon.cross(width: state.iconSize, height: state.iconSize, color: state.foregroundColor);
            },
          ),
        ),
        trailing: MateoButton(
          presentation: MateoButtonPresentation(
            label: i18n.post.publishButtonTitle,
            variant: MateoButtonVariant.primary,
            fit: MateoButtonFit.fit,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            trailingIconBuilder: (state) {
              return MateoIcon.paperPlaneUpRight(width: 14, height: 14, color: state.foregroundColor);
            },
          ),
          key: const ValueKey('post_publish_button'),
        ),
      ),
      body: const PostDetailsInput(),
    );
  }
}
