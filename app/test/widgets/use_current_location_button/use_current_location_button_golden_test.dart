import 'dart:async';

import 'package:alchemist/alchemist.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/use_current_location_button/current_location_state.dart';
import 'package:cataqui_app/widgets/use_current_location_button/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../utils/test_app.dart';
import 'fake_device_location.dart';

void main() {
  final goldenConfig = AlchemistConfig.current();
  AlchemistConfig.runWithConfig(
    config: goldenConfig.copyWith(ciGoldensConfig: goldenConfig.ciGoldensConfig.copyWith(obscureText: false)),
    run: () {
      goldenTest(
        'when the current-location button is resting, it should match the approved appearance',
        fileName: 'use_current_location_button_resting',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        builder: () => _UseCurrentLocationButtonGoldenTestData.buildComponent(
          deviceLocation: _UseCurrentLocationButtonGoldenTestData.deniedDeviceLocation(),
        ),
      );

      goldenTest(
        'when the current-location button is pressed, it should match the approved touch feedback',
        fileName: 'use_current_location_button_pressed',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        whilePerforming: press(find.byType(UseCurrentLocationButton), holdFor: const Duration(milliseconds: 150)),
        builder: () => _UseCurrentLocationButtonGoldenTestData.buildComponent(
          deviceLocation: _UseCurrentLocationButtonGoldenTestData.deniedDeviceLocation(),
        ),
      );

      goldenTest(
        'when the current address is loading, it should match the approved appearance',
        fileName: 'use_current_location_button_loading',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        whilePerforming: (tester) async {
          final container = ProviderScope.containerOf(tester.element(find.byType(UseCurrentLocationButton)));
          unawaited(container.read(currentLocationStateProvider.notifier).requestCurrentAddress());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 350));
          return null;
        },
        builder: () => _UseCurrentLocationButtonGoldenTestData.buildComponent(
          deviceLocation: FakeDeviceLocation(
            address: _UseCurrentLocationButtonGoldenTestData.address,
            permissionStatuses: [DeviceLocationPermissionStatus.denied],
            addressCompleter: Completer<DeviceLocationAddress>(),
          ),
        ),
      );

      goldenTest(
        'when the current address is resolved, it should match the approved appearance',
        fileName: 'use_current_location_button_resolved',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        builder: () => _UseCurrentLocationButtonGoldenTestData.buildComponent(
          deviceLocation: FakeDeviceLocation(
            address: _UseCurrentLocationButtonGoldenTestData.address,
            permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
          ),
        ),
      );

      goldenTest(
        'when a preferred current address label is unavailable, it should match the approved appearance',
        fileName: 'use_current_location_button_unavailable',
        constraints: const BoxConstraints.tightFor(width: 390, height: 120),
        builder: () => _UseCurrentLocationButtonGoldenTestData.buildComponent(
          deviceLocation: FakeDeviceLocation(
            address: const DeviceLocationAddress(
              coordinates: _UseCurrentLocationButtonGoldenTestData.coordinates,
              country: 'Brasil',
            ),
            permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
          ),
        ),
      );

      goldenTest(
        'when permission is permanently denied, it should match the approved recovery sheet',
        fileName: 'use_current_location_button_permission_sheet',
        constraints: const BoxConstraints.tightFor(width: 390, height: 844),
        whilePerforming: (tester) async {
          await tester.tap(find.byType(UseCurrentLocationButton));
          await tester.pump();
          await tester.pump(const Duration(seconds: 1));
          return null;
        },
        builder: _UseCurrentLocationButtonGoldenTestData.buildSheetApp,
      );
    },
  );
}

abstract final class _UseCurrentLocationButtonGoldenTestData {
  static const coordinates = DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18);
  static const address = DeviceLocationAddress(coordinates: coordinates, neighborhood: 'Pinheiros');

  static FakeDeviceLocation deniedDeviceLocation() {
    return FakeDeviceLocation(address: address, permissionStatuses: [DeviceLocationPermissionStatus.denied]);
  }

  static Widget buildComponent({required FakeDeviceLocation deviceLocation}) {
    return Localizations(
      locale: const Locale('pt', 'BR'),
      delegates: GlobalMaterialLocalizations.delegates,
      child: Center(
        child: SizedBox(
          width: 350,
          child: ProviderScope(
            overrides: [
              translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
              deviceLocationProvider.overrideWithValue(deviceLocation),
            ],
            child: UseCurrentLocationButton(onRequestedToUse: (_) {}),
          ),
        ),
      ),
    );
  }

  static Widget buildSheetApp() {
    return TestApp(
      mediaQueryData: const MediaQueryData(size: Size(390, 844), disableAnimations: true),
      providerOverrides: [
        translationProvider.overrideWithValue(AppLocale.ptBr.buildSync()),
        deviceLocationProvider.overrideWithValue(
          FakeDeviceLocation(
            address: address,
            permissionStatuses: [DeviceLocationPermissionStatus.denied],
            addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
          ),
        ),
      ],
      child: Builder(
        builder: (context) => Localizations.override(
          context: context,
          locale: const Locale('pt', 'BR'),
          delegates: GlobalMaterialLocalizations.delegates,
          child: SizedBox(width: 350, child: UseCurrentLocationButton(onRequestedToUse: (_) {})),
        ),
      ),
    );
  }
}
