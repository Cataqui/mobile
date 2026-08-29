import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/logos.g.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/enums/create_job_morph_tag.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_data.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_state.dart';
import 'package:cataqui_app/views/create_job/payment/create_job_payment_route.dart';
import 'package:cataqui_app/widgets/use_current_location_button/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'create_job_location_view_initial_body.dart';
part 'create_job_location_view_search_body.dart';

class CreateJobLocationView extends ConsumerStatefulWidget {
  const CreateJobLocationView({required this.jobId, super.key});

  final String jobId;

  @override
  ConsumerState<CreateJobLocationView> createState() => _CreateJobLocationViewState();
}

class _CreateJobLocationViewState extends ConsumerState<CreateJobLocationView> {
  final MateoTextController _searchTextController = MateoTextController();

  bool _hasAddressSearchStarted(CreateJobLocationData locationData) {
    final addressSearch = locationData.addressSearch;
    return addressSearch.isLoading || addressSearch.hasError || addressSearch.value != null;
  }

  void _openPayment() {
    unawaited(CreateJobPaymentRoute(jobId: widget.jobId).push<void>(context));
  }

  void _selectSearchedAddress(String addressId) {
    ref.read(createJobLocationStateProvider.notifier).selectAddress(addressId: addressId);
    _openPayment();
  }

  void _useCurrentLocation(DeviceLocationAddress address) {
    ref
        .read(createJobStateProvider.notifier)
        .setLocation(latitude: address.coordinates.latitude, longitude: address.coordinates.longitude);
    _openPayment();
  }

  @override
  void dispose() {
    _searchTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final locationState = ref.watch(createJobLocationStateProvider.notifier);

    return MateoScrollableView(
      backgroundColor: Colors.transparent,
      keyboardViewportBehavior: MateoViewKeyboardViewportBehavior.resize,
      edgeFade: (
        top: MateoEdgeFadeStyle(color: context.mateo.colorScheme.background),
        bottom: MateoEdgeFadeStyle(color: context.mateo.colorScheme.background),
      ),
      header: MateoViewHeader(
        title: i18n.createJob.location.title,
        leading: MateoFloatingActionButton(
          key: const ValueKey('create_job_location_back_button'),
          onPressed: context.pop,
          semanticLabel: i18n.createJob.location.backButtonSemanticLabel,
          backgroundColor: context.mateo.colorScheme.bottomSheet.background,
          foregroundColor: context.mateo.colorScheme.text.primary,
          borderSide: BorderSide.none,
          size: 50,
          iconSize: 20,
          iconBuilder: (state) =>
              MateoIcon.arrowLeft(width: state.iconSize, height: state.iconSize, color: state.foregroundColor),
        ),
      ),
      footer: Column(
        key: const ValueKey('create_job_location_search_footer'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 24, bottom: 12),
            child: $Logos.googleMaps(
              key: const ValueKey('create_job_location_google_maps_attribution'),
              height: 14,
              color1: switch (Theme.brightnessOf(context)) {
                Brightness.dark => throw UnimplementedError('Dark mode not implemented yet'),
                Brightness.light => context.mateo.palette.neutral[8],
              },
            ),
          ),

          MorphForeground(
            key: const ValueKey('create_job_location_search_foreground'),
            child: Consumer(
              builder: (context, ref, _) {
                final hasAddressSearchStarted = ref.watch(
                  createJobLocationStateProvider.select(_hasAddressSearchStarted),
                );

                return MateoTextField(
                  key: const ValueKey('create_job_location_search_field'),
                  controller: _searchTextController,
                  placeholder: i18n.createJob.location.searchPlaceholder,
                  variant: MateoTextFieldVariant.search,
                  textInputAction: TextInputAction.search,
                  unfocusOnTapOutside: !hasAddressSearchStarted,
                  onChanged: (query) => unawaited(locationState.searchAddresses(query: query)),
                );
              },
            ),
          ),
        ],
      ),
      bodySurfaceBuilder: (context, content) {
        return Morph(
          tag: CreateJobMorphTag.surface,
          curve: Curves.fastOutSlowIn,
          switchThreshold: 0.05,
          child: Container(
            key: const ValueKey('create_job_location_surface'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.mateo.colorScheme.background,
              borderRadius: BorderRadius.circular(40),
            ),
            child: content,
          ),
        );
      },
      body: Consumer(
        builder: (context, ref, _) {
          final hasAddressSearchStarted = ref.watch(createJobLocationStateProvider.select(_hasAddressSearchStarted));

          if (!hasAddressSearchStarted) {
            return _CreateJobLocationViewInitialBody(
              searchTextController: _searchTextController,
              onLocationSelected: _useCurrentLocation,
            );
          }

          return _CreateJobLocationViewSearchBody(onAddressSelected: _selectSearchedAddress);
        },
      ),
    );
  }
}
