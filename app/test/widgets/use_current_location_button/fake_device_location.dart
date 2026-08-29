import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

class FakeDeviceLocation extends Fake implements DeviceLocation {
  FakeDeviceLocation({
    required this.address,
    required this.permissionStatuses,
    this.addressCompleter,
    this.addressError,
    List<Exception?> addressErrors = const [],
    this.openLocationSettingsError,
    this.openLocationSettingsResult = true,
  }) : addressErrors = addressErrors.toList();

  final DeviceLocationAddress address;
  final Completer<DeviceLocationAddress>? addressCompleter;
  final List<DeviceLocationPermissionStatus> permissionStatuses;
  final List<Exception?> addressErrors;
  Exception? addressError;
  Exception? openLocationSettingsError;
  bool openLocationSettingsResult;
  int addressRequestCount = 0;
  int openLocationSettingsRequestCount = 0;
  Locale? lastRequestedLocale;
  final List<bool> requestPermissionValues = [];

  @override
  Future<DeviceLocationPermissionStatus> get permissionStatus async {
    if (permissionStatuses.length == 1) return permissionStatuses.single;

    return permissionStatuses.removeAt(0);
  }

  @override
  Future<DeviceLocationAddress> getCurrentAddress({bool requestPermission = true, Locale? locale}) async {
    addressRequestCount += 1;
    requestPermissionValues.add(requestPermission);
    lastRequestedLocale = locale;

    if (addressErrors.isNotEmpty) {
      final addressError = addressErrors.removeAt(0);
      if (addressError != null) throw addressError;

      return address;
    }

    final addressError = this.addressError;
    if (addressError != null) throw addressError;

    final addressCompleter = this.addressCompleter;
    if (addressCompleter != null) return addressCompleter.future;

    return address;
  }

  @override
  Future<bool> openLocationSettings() async {
    openLocationSettingsRequestCount += 1;
    final openLocationSettingsError = this.openLocationSettingsError;
    if (openLocationSettingsError != null) throw openLocationSettingsError;

    return openLocationSettingsResult;
  }
}
