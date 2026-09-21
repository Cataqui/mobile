import 'dart:async';

import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/extensions/device_location_address_extension.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/logos.g.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/views/post/location/post_location_data.dart';
import 'package:cataqui_app/views/post/location/post_location_state.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/widgets/use_current_location_button/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'post_location_slide_animation.dart';
part 'post_location_view_initial_body.dart';
part 'post_location_view_search_body.dart';

class PostLocationView extends ConsumerStatefulWidget {
  const PostLocationView({super.key});

  static Future<void> push({required BuildContext context}) {
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);
    _PostLocationSlideAnimation? slideAnimation;

    final route = PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierLabel: ProviderScope.containerOf(
        context,
        listen: false,
      ).read(translationProvider).post.location.closeButtonSemanticLabel,
      barrierColor: Colors.transparent,
      transitionDuration: animationsDisabled ? Duration.zero : const Duration(milliseconds: 600),
      reverseTransitionDuration: animationsDisabled ? Duration.zero : const Duration(milliseconds: 260),
      pageBuilder: (routeContext, _, _) => const PostLocationView(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: .zero,
        ).animate(slideAnimation ??= _PostLocationSlideAnimation(parent: animation)),
        child: child,
      ),
    );
    unawaited(route.completed.whenComplete(() => slideAnimation?.dispose()));
    return Navigator.of(context).push<void>(route);
  }

  @override
  ConsumerState<PostLocationView> createState() => _PostLocationViewState();
}

class _PostLocationViewState extends ConsumerState<PostLocationView> {
  final TextEditingController _searchTextController = TextEditingController();

  bool _hasAddressSearchStarted(PostLocationData locationData) {
    final addressSearch = locationData.addressSearch;
    return addressSearch.isLoading || addressSearch.hasError || addressSearch.value != null;
  }

  void _close() => Navigator.of(context).pop();

  void _closeAfterComposerPaints() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _close();
    });
  }

  void _selectSearchedAddress(AddressSuggestionDto suggestion) {
    ref.read(postLocationStateProvider.notifier).selectAddress(suggestion: suggestion);
    _closeAfterComposerPaints();
  }

  void _useCurrentLocation(DeviceLocationAddress address) {
    ref
        .read(postStateProvider.notifier)
        .setLocation(
          latitude: address.coordinates.latitude,
          longitude: address.coordinates.longitude,
          locationTitle: address.jobLocation() ?? ref.read(translationProvider).useCurrentLocationButton.unavailable,
        );
    _closeAfterComposerPaints();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final locationState = ref.watch(postLocationStateProvider.notifier);
    final hasAddressSearchStarted = ref.watch(postLocationStateProvider.select(_hasAddressSearchStarted));
    return MateoView(
      key: const ValueKey('post_location_view'),
      header: MateoViewHeader(
        principal: MateoTextInput(
          key: const ValueKey('post_location_search_field'),
          controller: _searchTextController,
          autofocus: true,
          placeholder: i18n.post.location.searchPlaceholder,
          presentation: const .search(variant: .filled, size: .small),
          onChanged: (query) {
            unawaited(locationState.searchAddresses(query: query));
          },
        ),
        trailing: MateoButton(
          key: const ValueKey('post_location_close_button'),
          onPressed: _close,
          presentation: .icon(
            variant: .primary.base,
            elevation: 1,
            semanticLabel: i18n.post.location.closeButtonSemanticLabel,

            icon: const MateoIcon(.cross),
          ),
        ),
      ),
      footer: MateoViewFooter(
        principal: Align(
          key: const ValueKey('post_location_search_footer'),
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: $Logos.googleMaps(
              key: const ValueKey('post_location_google_maps_attribution'),
              height: 14,
              color1: switch (MateoTheme.of(context).brightness) {
                Brightness.dark => throw UnimplementedError('Dark mode not implemented yet'),
                Brightness.light => MateoTheme.of(context).palette.neutral[8],
              },
            ),
          ),
        ),
      ),
      surface: .scrollable(
        key: const ValueKey('post_location_view_surface'),
        color: MateoTheme.of(context).colorScheme.background,
        shape: const .rounded(radius: 0),
        edgeEffect: .fade(at: [.top]),
        child: Column(
          children: [
            Expanded(
              child: hasAddressSearchStarted
                  ? _PostLocationViewSearchBody(onAddressSelected: _selectSearchedAddress)
                  : _PostLocationViewInitialBody(onLocationSelected: _useCurrentLocation),
            ),
          ],
        ),
      ),
    );
  }
}
