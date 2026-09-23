import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_route.dart';
import 'package:cataqui_app/views/post/post_details_input/post_details_input.dart';
import 'package:cataqui_app/views/post/post_route.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

class PostView extends ConsumerStatefulWidget {
  const PostView({super.key});

  @override
  ConsumerState<PostView> createState() => _PostViewState();
}

class _PostViewState extends ConsumerState<PostView> with RouteAware {
  late final RouteObserver<ModalRoute<void>> _routeObserver;
  VoidCallback? _showPublishingToast;
  bool _isPostVisible = true;
  bool _publishingToastShown = false;

  void _preparePublishingToast() {
    if (_showPublishingToast != null) return;

    final toastContext = Navigator.of(context, rootNavigator: true).context;
    final providerContainer = ProviderScope.containerOf(context, listen: false);
    final appToast = ref.read(appToastProvider);
    final router = GoRouter.maybeOf(context);
    final loadingMessage = ref.read(translationProvider).post.publishing.loading;

    _showPublishingToast = () {
      if (!toastContext.mounted || _publishingToastShown || !providerContainer.read(postStateProvider).isPublishing) {
        return;
      }
      appToast.showLoading(
        toastContext,
        message: loadingMessage,
        duration: const .untilDismissed(),
        onPressed: () {
          if (!toastContext.mounted || router == null || !providerContainer.read(postStateProvider).isPublishing) {
            return;
          }
          if (router.state.matchedLocation == const PostRoute().location) return;
          unawaited(const PostRoute().push<void>(toastContext));
        },
      );
      _publishingToastShown = true;
    };
  }

  void _schedulePublishingToast() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showPublishingToast?.call());
  }

  Future<void> _publish() async {
    final toastContext = Navigator.of(context, rootNavigator: true).context;
    final appToast = ref.read(appToastProvider);
    final publishingMessages = ref.read(translationProvider).post.publishing;
    final router = GoRouter.maybeOf(context);
    _preparePublishingToast();

    try {
      final publishFuture = ref.read(postStateProvider.notifier).publish();
      await publishFuture;
      if (!toastContext.mounted) return;
      final isPostVisible = router == null
          ? _isPostVisible
          : router.state.matchedLocation == const PostRoute().location;
      if (!isPostVisible) {
        appToast.showSuccess(toastContext, message: publishingMessages.success);
        return;
      }
      if (_publishingToastShown) dismissMateoToast(context: toastContext);
    } on Object catch (error) {
      if (toastContext.mounted) {
        if (_publishingToastShown) dismissMateoToast(context: toastContext);
        appToast.maybeShowError(toastContext, error: error, message: publishingMessages.error);
      }
    } finally {
      _showPublishingToast = null;
      _publishingToastShown = false;
    }
  }

  @override
  void initState() {
    super.initState();
    _routeObserver = ref.read(routeObserverProvider);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of<void>(context);
    if (route != null) _routeObserver.subscribe(this, route);
    if (ref.read(postStateProvider).isPublishing) _preparePublishingToast();
  }

  @override
  void dispose() {
    _routeObserver.unsubscribe(this);
    _isPostVisible = false;
    if (_showPublishingToast != null) _schedulePublishingToast();
    super.dispose();
  }

  @override
  void didPushNext() {
    _isPostVisible = false;
    if (_showPublishingToast != null) _schedulePublishingToast();
  }

  @override
  void didPopNext() {
    _isPostVisible = true;
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final publishAction = ref.watch(
      postStateProvider.select((postData) => (canPublish: postData.canPublish, isPublishing: postData.isPublishing)),
    );

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
          isLoading: publishAction.isPublishing,
          onPressed: publishAction.canPublish ? _publish : null,
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
