import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/post/post_details_input/post_details_input.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class PostView extends ConsumerStatefulWidget {
  const PostView({super.key});

  @override
  ConsumerState<PostView> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostView> {
  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final canPublish = ref.watch(postStateProvider.select((postData) => postData.canPublish));

    return MateoView(
      // avoidBottomInset: true,
      key: const ValueKey('post_view'),
      header: MateoViewHeader(
        key: const ValueKey('post_header'),
        principal: Text(i18n.post.title),
        leading: MateoButton(
          key: const ValueKey('post_close_button'),
          onPressed: () async {
            final navigator = Navigator.of(context);

            if (navigator.canPop()) {
              navigator.pop();
              return;
            }

            await ref.read(appRouterProvider.notifier).go(context, const FeedRoute());
          },
          presentation: .icon(
            variant: .primary.base,
            elevation: 1,
            semanticLabel: i18n.post.closeButtonSemanticLabel,

            icon: const MateoIcon(.cross),
          ),
        ),
        trailing: MateoButton(
          presentation: .label(
            label: i18n.post.publishButtonTitle,
            variant: .primary.accent,
            size: .mini,
            width: .fit,
            leadingIcon: const MateoIcon(.paperPlaneUpRight),
          ),
          key: const ValueKey('post_publish_button'),
          onPressed: canPublish ? () {} : null,
        ),
      ),
      surface: .scrollable(
        color: MateoTheme.of(context).colorScheme.background,
        edgeEffect: .fade(at: [.top]),
        child: const PostDetailsInput(),
      ),
    );
  }
}
