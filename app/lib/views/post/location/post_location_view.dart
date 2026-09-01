import 'dart:async';

import 'package:cataqui_app/core/dtos/address_suggestion_dto.dart';
import 'package:cataqui_app/core/extensions/device_location_address_extension.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/logos.g.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/views/post/location/enums/post_location_morph_tag.dart';
import 'package:cataqui_app/views/post/location/post_location_data.dart';
import 'package:cataqui_app/views/post/location/post_location_state.dart';
import 'package:cataqui_app/views/post/post_state.dart';
import 'package:cataqui_app/widgets/use_current_location_button/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'post_location_view_initial_body.dart';
part 'post_location_view_search_body.dart';

class PostLocationView extends ConsumerStatefulWidget {
  const PostLocationView({super.key});

  static Future<void> push({required BuildContext context}) {
    final animationsDisabled = MediaQuery.disableAnimationsOf(context);

    return Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierLabel: ProviderScope.containerOf(
          context,
          listen: false,
        ).read(translationProvider).post.location.closeButtonSemanticLabel,
        barrierColor: Colors.black.withValues(alpha: 0.1),
        transitionDuration: animationsDisabled ? Duration.zero : const Duration(milliseconds: 320),
        reverseTransitionDuration: animationsDisabled ? Duration.zero : const Duration(milliseconds: 270),
        pageBuilder: (routeContext, _, _) => const PostLocationView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
      ),
    );
  }

  @override
  ConsumerState<PostLocationView> createState() => _PostLocationViewState();
}

class _PostLocationViewState extends ConsumerState<PostLocationView> {
  final MateoTextController _searchTextController = MateoTextController();
  bool _isMorphSettled = false;

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
    final surfaceColor = context.mateo.colorScheme.background;
    final surfaceBorderRadius = MediaQuery.disableAnimationsOf(context) || _isMorphSettled
        ? BorderRadius.zero
        : BorderRadius.circular(43);

    return MateoScrollableView(
      key: const ValueKey('post_location_view'),
      keyboardViewportBehavior: MateoViewKeyboardViewportBehavior.resize,
      edgeFade: (top: MateoEdgeFadeStyle(color: surfaceColor), bottom: null),
      backgroundBuilder: (context, content) => Morph(
        tag: PostLocationMorphTag.surface,
        duration: Duration.zero,
        curve: Curves.easeOutCubic,
        watchDestination: true,
        switchThreshold: 0.1,
        onReceived: () {
          if (_isMorphSettled) return;
          setState(() => _isMorphSettled = true);
        },
        child: Container(
          key: const ValueKey('post_location_view_surface'),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(color: surfaceColor, borderRadius: surfaceBorderRadius),
          child: content,
        ),
      ),
      header: MorphSibling(
        tag: PostLocationMorphTag.surface,
        paintAboveMorph: true,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: const Interval(0.9, 1)),
            child: child,
          );
        },
        child: MateoViewHeader(
          title: MateoTextField(
            key: const ValueKey('post_location_search_field'),
            controller: _searchTextController,
            autofocus: true,
            placeholder: i18n.post.location.searchPlaceholder,
            variant: MateoTextFieldVariant.search,
            textInputAction: TextInputAction.search,
            unfocusOnTapOutside: false,
            onChanged: (query) {
              unawaited(locationState.searchAddresses(query: query));
            },
          ),
          trailing: MateoFloatingActionButton(
            key: const ValueKey('post_location_close_button'),
            onPressed: _close,
            semanticLabel: i18n.post.location.closeButtonSemanticLabel,
            size: 54,
            iconSize: 17,
            iconBuilder: (state) {
              return MateoIcon.cross(width: state.iconSize, height: state.iconSize, color: state.foregroundColor);
            },
          ),
        ),
      ),
      footer: MorphSibling(
        tag: PostLocationMorphTag.surface,
        paintAboveMorph: true,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: CurvedAnimation(parent: animation, curve: const Interval(0.9, 1)),
          child: child,
        ),
        child: Align(
          key: const ValueKey('post_location_search_footer'),
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 4, bottom: 12),
            child: $Logos.googleMaps(
              key: const ValueKey('post_location_google_maps_attribution'),
              height: 14,
              color1: switch (Theme.brightnessOf(context)) {
                Brightness.dark => throw UnimplementedError('Dark mode not implemented yet'),
                Brightness.light => context.mateo.palette.neutral[8],
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 22, right: 16),
        child: Column(
          children: [
            if (!hasAddressSearchStarted) const SizedBox(height: 20),
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
