import 'dart:async';

import 'package:cataqui_app/app_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/widgets/use_current_location_button/current_location_data.dart';
import 'package:clock/clock.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:slang_flutter/slang_flutter.dart';

part 'current_location_state.g.dart';

@Riverpod(keepAlive: true)
class CurrentLocationState extends _$CurrentLocationState {
  late DeviceLocation _deviceLocation;
  DateTime? _addressResolvedAt;
  Timer? _addressExpirationTimer;
  Future<CurrentLocationData?>? _pendingAddressRequest;

  @override
  Future<CurrentLocationData> build() async {
    _deviceLocation = ref.watch(deviceLocationProvider);
    ref.watch(appStateProvider);
    _pendingAddressRequest = null;
    ref.onDispose(() => _addressExpirationTimer?.cancel());

    try {
      final currentPermissionStatus = await _deviceLocation.permissionStatus;

      switch (currentPermissionStatus) {
        case DeviceLocationPermissionStatus.whileInUse:
        case DeviceLocationPermissionStatus.always:
          return await _resolveAddress(requestPermission: false) ??
              const CurrentLocationData.failure(reason: DeviceLocationExceptionReason.operationUnavailable);
        case DeviceLocationPermissionStatus.notDetermined:
        case DeviceLocationPermissionStatus.denied:
        case DeviceLocationPermissionStatus.deniedForever:
        case DeviceLocationPermissionStatus.restricted:
          return CurrentLocationData.permission(status: currentPermissionStatus);
      }
    } on DeviceLocationException catch (error) {
      return _dataFor(error);
    } on Object {
      return const CurrentLocationData.failure(reason: DeviceLocationExceptionReason.operationUnavailable);
    }
  }

  Future<DeviceLocationAddress?> requestCurrentAddress() async {
    if (state.value case ResolvedCurrentLocationData(:final address)) {
      final addressResolvedAt = _addressResolvedAt;

      if (addressResolvedAt != null && clock.now().difference(addressResolvedAt) < const Duration(seconds: 60)) {
        return address;
      }
    }

    state = const AsyncLoading<CurrentLocationData>();
    final data = await _resolveAddress(requestPermission: true);
    if (!ref.mounted || data == null) return null;

    state = AsyncData<CurrentLocationData>(data);

    return switch (data) {
      ResolvedCurrentLocationData(:final address) => address,
      CurrentLocationPermissionData() || FailedCurrentLocationData() => null,
    };
  }

  Future<DeviceLocationAddress?> resumeCurrentAddressRequestAfterSettingsPermission() async {
    state = const AsyncLoading<CurrentLocationData>();

    CurrentLocationData data;

    try {
      final permissionStatus = await _deviceLocation.permissionStatus;
      if (!ref.mounted) return null;

      if (permissionStatus == DeviceLocationPermissionStatus.restricted) {
        data = const CurrentLocationData.permission(status: DeviceLocationPermissionStatus.restricted);
      } else {
        data =
            await _resolveAddress(requestPermission: !permissionStatus.isGranted) ??
            const CurrentLocationData.failure(reason: DeviceLocationExceptionReason.operationUnavailable);
      }
    } on DeviceLocationException catch (error) {
      data = _dataFor(error);
    } on Object {
      data = const CurrentLocationData.failure(reason: DeviceLocationExceptionReason.operationUnavailable);
    }

    if (!ref.mounted) return null;

    state = AsyncData<CurrentLocationData>(data);
    return switch (data) {
      ResolvedCurrentLocationData(:final address) => address,
      CurrentLocationPermissionData() || FailedCurrentLocationData() => null,
    };
  }

  CurrentLocationData _dataFor(Object error) {
    if (error is! DeviceLocationException) {
      return const CurrentLocationData.failure(reason: DeviceLocationExceptionReason.operationUnavailable);
    }

    return switch (error.reason) {
      DeviceLocationExceptionReason.permissionDenied => const CurrentLocationData.permission(
        status: DeviceLocationPermissionStatus.denied,
      ),
      DeviceLocationExceptionReason.permissionPermanentlyDenied => const CurrentLocationData.permission(
        status: DeviceLocationPermissionStatus.deniedForever,
      ),
      DeviceLocationExceptionReason.servicesDisabled ||
      DeviceLocationExceptionReason.configurationMissing ||
      DeviceLocationExceptionReason.unsupportedPlatform ||
      DeviceLocationExceptionReason.operationUnavailable ||
      DeviceLocationExceptionReason.coordinatesUnavailable => CurrentLocationData.failure(reason: error.reason),
    };
  }

  Future<CurrentLocationData?> _performAddressRequest({required bool requestPermission}) async {
    Object? finalError;
    for (var attempt = 0; attempt < 3; attempt += 1) {
      if (!ref.mounted) return null;

      try {
        final address = await _deviceLocation.getCurrentAddress(
          requestPermission: attempt == 0 && requestPermission,
          locale: ref.read(appStateProvider).currentLocale.flutterLocale,
        );
        if (!ref.mounted) return null;

        _addressResolvedAt = clock.now();
        _addressExpirationTimer?.cancel();
        _addressExpirationTimer = Timer(const Duration(seconds: 60), ref.invalidateSelf);
        return CurrentLocationData.resolved(address: address);
      } on Object catch (error) {
        finalError = error;
        if (error is DeviceLocationException &&
            (error.reason == DeviceLocationExceptionReason.permissionDenied ||
                error.reason == DeviceLocationExceptionReason.permissionPermanentlyDenied)) {
          break;
        }
      }

      if (attempt == 2) break;

      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    if (!ref.mounted) return null;

    return _dataFor(finalError ?? StateError('Current location resolution finished without a result.'));
  }

  Future<CurrentLocationData?> _resolveAddress({required bool requestPermission}) {
    final pendingAddressRequest = _pendingAddressRequest;
    if (pendingAddressRequest != null) return pendingAddressRequest;

    late final Future<CurrentLocationData?> request;
    request = _performAddressRequest(requestPermission: requestPermission).whenComplete(() {
      if (identical(_pendingAddressRequest, request)) _pendingAddressRequest = null;
    });
    _pendingAddressRequest = request;
    return request;
  }
}
