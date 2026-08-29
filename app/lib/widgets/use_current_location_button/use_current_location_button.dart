import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/gen/lotties.g.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/use_current_location_button/current_location_data.dart';
import 'package:cataqui_app/widgets/use_current_location_button/current_location_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'location_permission_sheet.dart';

class UseCurrentLocationButton extends ConsumerStatefulWidget {
  const UseCurrentLocationButton({required this.onRequestedToUse, super.key});

  final void Function(DeviceLocationAddress address) onRequestedToUse;

  @override
  ConsumerState<UseCurrentLocationButton> createState() => _UseCurrentLocationButtonState();
}

class _UseCurrentLocationButtonState extends ConsumerState<UseCurrentLocationButton> with WidgetsBindingObserver {
  bool _isUseRequestPending = false;
  bool _shouldUseAfterSettings = false;

  ({Color background, Color indicator}) _colors(AsyncValue<CurrentLocationData> currentLocation) {
    return switch (Theme.of(context).brightness) {
      Brightness.light => (
        background: context.mateo.palette.neutral[2],
        indicator: switch (currentLocation.value) {
          ResolvedCurrentLocationData(:final address)
              when address.neighborhood != null || address.city != null || address.street != null =>
            context.mateo.palette.green[9],
          CurrentLocationPermissionData() ||
          ResolvedCurrentLocationData() ||
          FailedCurrentLocationData() ||
          null => context.mateo.palette.red,
        },
      ),
      Brightness.dark => throw UnsupportedError('CurrentLocationButton does not support dark mode.'),
    };
  }

  String _description(Translations i18n, AsyncValue<CurrentLocationData> currentLocation) {
    if (currentLocation.isLoading) return i18n.useCurrentLocationButton.loading;

    final data = currentLocation.value;
    if (data == null) return i18n.useCurrentLocationButton.unavailable;

    return switch (data) {
      CurrentLocationPermissionData(:final status) => switch (status) {
        DeviceLocationPermissionStatus.restricted => i18n.useCurrentLocationButton.restricted,
        DeviceLocationPermissionStatus.notDetermined ||
        DeviceLocationPermissionStatus.denied ||
        DeviceLocationPermissionStatus.deniedForever ||
        DeviceLocationPermissionStatus.whileInUse ||
        DeviceLocationPermissionStatus.always => i18n.useCurrentLocationButton.permissionGuidance,
      },
      ResolvedCurrentLocationData(:final address) => switch ((address.neighborhood, address.city)) {
        (final neighborhood?, final city?) => '$neighborhood, $city',
        (final neighborhood?, null) => neighborhood,
        (null, final city?) => city,
        (null, null) => address.street ?? i18n.useCurrentLocationButton.unavailable,
      },
      FailedCurrentLocationData(:final reason) => switch (reason) {
        DeviceLocationExceptionReason.servicesDisabled => i18n.useCurrentLocationButton.servicesDisabled,
        DeviceLocationExceptionReason.permissionDenied ||
        DeviceLocationExceptionReason.permissionPermanentlyDenied => i18n.useCurrentLocationButton.permissionGuidance,
        DeviceLocationExceptionReason.operationUnavailable ||
        DeviceLocationExceptionReason.coordinatesUnavailable ||
        DeviceLocationExceptionReason.configurationMissing ||
        DeviceLocationExceptionReason.unsupportedPlatform => i18n.useCurrentLocationButton.unavailable,
      },
    };
  }

  DeviceLocationPermissionStatus? _permissionStatus() {
    return switch (ref.read(currentLocationStateProvider).value) {
      CurrentLocationPermissionData(:final status) => status,
      ResolvedCurrentLocationData() || FailedCurrentLocationData() || null => null,
    };
  }

  Future<void> _showSettingsOpenError(Object error) async {
    if (!mounted) return;

    ref
        .read(appToastProvider)
        .maybeShowError(
          context,
          error: error,
          message: ref.read(translationProvider).useCurrentLocationButton.settingsOpenError,
        );
  }

  Future<void> _openLocationSettings() async {
    _shouldUseAfterSettings = true;

    try {
      final didOpen = await ref.read(deviceLocationProvider).openLocationSettings();
      if (didOpen) return;

      _shouldUseAfterSettings = false;
      await _showSettingsOpenError(StateError('The operating system rejected location settings navigation.'));
    } on Object catch (error) {
      _shouldUseAfterSettings = false;
      await _showSettingsOpenError(error);
    }
  }

  Future<void> _showPermanentDenialSheet() async {
    await _LocationPermissionSheet.show(context: context, onOpenSettings: _openLocationSettings);
  }

  Future<void> _handleRequestedToUse(Future<void> animation) async {
    if (_isUseRequestPending) return;

    setState(() => _isUseRequestPending = true);
    try {
      if (_permissionStatus() == DeviceLocationPermissionStatus.deniedForever) {
        await _showPermanentDenialSheet();
        return;
      }

      if (_permissionStatus() == DeviceLocationPermissionStatus.restricted) return;

      final address = await ref.read(currentLocationStateProvider.notifier).requestCurrentAddress();
      if (!mounted) return;

      if (address == null) {
        if (_permissionStatus() == DeviceLocationPermissionStatus.deniedForever) {
          await _showPermanentDenialSheet();
        }

        return;
      }

      await animation;
      if (!mounted) return;

      widget.onRequestedToUse(address);
    } finally {
      if (mounted) setState(() => _isUseRequestPending = false);
    }
  }

  Future<void> _completeSettingsRequest() async {
    _shouldUseAfterSettings = false;
    if (_isUseRequestPending || !mounted) return;

    setState(() => _isUseRequestPending = true);

    try {
      final address = await ref
          .read(currentLocationStateProvider.notifier)
          .resumeCurrentAddressRequestAfterSettingsPermission();
      if (!mounted) return;
      if (address == null) {
        if (_permissionStatus() != DeviceLocationPermissionStatus.restricted) {
          await _showPermanentDenialSheet();
        }
        return;
      }

      widget.onRequestedToUse(address);
    } finally {
      if (mounted) setState(() => _isUseRequestPending = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_shouldUseAfterSettings || !mounted) return;

    unawaited(_completeSettingsRequest());
  }

  @override
  Widget build(BuildContext context) {
    final i18n = ref.watch(translationProvider);
    final currentLocation = ref.watch(currentLocationStateProvider);
    final description = _description(i18n, currentLocation);
    final transitionDuration = MediaQuery.disableAnimationsOf(context)
        ? const Duration(microseconds: 1)
        : const Duration(milliseconds: 350);

    return Semantics(
      button: true,
      label: i18n.useCurrentLocationButton.title,
      value: description,
      liveRegion: true,
      excludeSemantics: true,
      child: MateoTap(
        animation: MateoTapAnimationType.scale,
        onPressed: _isUseRequestPending ? null : _handleRequestedToUse,
        child: Container(
          key: const ValueKey('create_job_current_location'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: _colors(currentLocation).background,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                i18n.useCurrentLocationButton.title,
                style: TextStyle(
                  color: context.mateo.colorScheme.text.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  AnimatedSize(
                    key: const ValueKey('create_job_current_location_circle'),
                    duration: transitionDuration,
                    curve: Curves.easeInOutCubic,
                    alignment: Alignment.centerLeft,
                    clipBehavior: Clip.none,
                    child: AnimatedSwitcher(
                      duration: transitionDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.center,
                        clipBehavior: Clip.none,
                        children: [
                          for (final previousChild in previousChildren)
                            Align(widthFactor: 0, heightFactor: 0, child: previousChild),
                          if (currentChild != null) currentChild,
                        ],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween<double>(begin: .6, end: 1).animate(animation),
                          child: child,
                        ),
                      ),
                      child: currentLocation.isLoading
                          ? MateoCircularLoadingIndicator(
                              key: const ValueKey((isLoading: true, isResolved: false)),
                              size: 15,
                              color: context.mateo.palette.blue[9],
                              trackColor: context.mateo.palette.blue[4],
                            )
                          : Container(
                              key: ValueKey((
                                isLoading: false,
                                isResolved: currentLocation.value is ResolvedCurrentLocationData,
                              )),
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: _colors(currentLocation).indicator,
                                shape: BoxShape.circle,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AnimatedSwitcher(
                      key: const ValueKey('create_job_location_permission_guidance'),
                      duration: transitionDuration,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      layoutBuilder: (currentChild, previousChildren) => Stack(
                        alignment: Alignment.centerLeft,
                        clipBehavior: Clip.none,
                        children: [...previousChildren, if (currentChild != null) currentChild],
                      ),
                      transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
                      child: Text(
                        description,
                        key: ValueKey(description),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.mateo.colorScheme.text.tertiary,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
