import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:cataqui_app/widgets/use_current_location_button/use_current_location_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import '../../fakes.dart';
import '../../utils/test_app.dart';

void main() {
  const coordinates = DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18);
  const neighborhoodAddress = DeviceLocationAddress(
    coordinates: coordinates,
    neighborhood: 'Pinheiros',
    street: 'Rua dos Pinheiros',
    name: 'Mercado Municipal',
    city: 'São Paulo',
  );
  late Translations i18n;

  setUp(() => i18n = AppLocale.ptBr.buildSync());

  Future<void> pumpButton(
    WidgetTester tester, {
    required FakeDeviceLocation deviceLocationService,
    required void Function(DeviceLocationAddress address) onRequestedToUse,
    MediaQueryData? mediaQueryData,
  }) async {
    await tester.pumpWidget(
      TestApp(
        mediaQueryData: mediaQueryData ?? const MediaQueryData(disableAnimations: true),
        providerOverrides: [
          translationProvider.overrideWithValue(i18n),
          deviceLocationProvider.overrideWithValue(deviceLocationService),
        ],
        child: Builder(
          builder: (context) => Localizations.override(
            context: context,
            locale: const Locale('pt', 'BR'),
            delegates: GlobalMaterialLocalizations.delegates,
            child: UseCurrentLocationButton(onRequestedToUse: onRequestedToUse),
          ),
        ),
      ),
    );
    if (mediaQueryData?.disableAnimations == false) {
      await tester.pump(const Duration(milliseconds: 350));
      return;
    }
    await tester.pumpAndSettle();
  }

  FakeDeviceLocation buildService({
    DeviceLocationAddress address = neighborhoodAddress,
    List<DeviceLocationPermissionStatus> permissionStatuses = const [DeviceLocationPermissionStatus.denied],
    Completer<DeviceLocationAddress>? addressCompleter,
    Exception? addressError,
    List<Exception?> addressErrors = const [],
    bool openLocationSettingsResult = true,
  }) {
    return FakeDeviceLocation(
      address: address,
      permissionStatuses: permissionStatuses.toList(),
      addressCompleter: addressCompleter,
      addressError: addressError,
      addressErrors: addressErrors,
      openLocationSettingsResult: openLocationSettingsResult,
    );
  }

  Future<void> pumpRetryDelays(WidgetTester tester, {int retryCount = 2}) async {
    for (var retry = 0; retry < retryCount; retry += 1) {
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('when permission is denied, it should show localized permission guidance without requesting an address', (
    tester,
  ) async {
    final service = buildService();
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    expect(
      <Object?>[
        find.text(i18n.useCurrentLocationButton.permissionGuidance).evaluate().length,
        service.addressRequestCount,
      ],
      <Object?>[1, 0],
    );
  });

  testWidgets('when current location is resting, it should show the pulse indicator', (tester) async {
    final service = buildService();
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    expect(tester.widget<AnimatedOpacity>(find.byKey(const ValueKey('current_location_pulse_transition'))).opacity, 1);
  });

  testWidgets('when current location is loading, it should keep the loading indicator', (tester) async {
    final service = buildService(addressCompleter: Completer<DeviceLocationAddress>());
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      (
        loadingOpacity: tester
            .widget<AnimatedOpacity>(find.byKey(const ValueKey('current_location_loading_transition')))
            .opacity,
        pulseOpacity: tester
            .widget<AnimatedOpacity>(find.byKey(const ValueKey('current_location_pulse_transition')))
            .opacity,
      ),
      (loadingOpacity: 1, pulseOpacity: 0),
    );
  });

  testWidgets('when loading resolves, it should crossfade without recreating the loading indicator', (tester) async {
    final addressCompleter = Completer<DeviceLocationAddress>();
    final service = buildService(addressCompleter: addressCompleter);
    await pumpButton(
      tester,
      deviceLocationService: service,
      onRequestedToUse: (_) {},
      mediaQueryData: const MediaQueryData(disableAnimations: false),
    );
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    final loadingIndicatorState = tester.state(find.byType(MateoCircularLoadingIndicator));

    addressCompleter.complete(neighborhoodAddress);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    final transitioningLoadingIndicatorStates = tester.stateList(find.byType(MateoCircularLoadingIndicator)).toList();

    expect(
      (
        loadingIndicatorCount: transitioningLoadingIndicatorStates.length,
        preservesLoadingIndicatorState:
            transitioningLoadingIndicatorStates.length == 1 &&
            identical(transitioningLoadingIndicatorStates.single, loadingIndicatorState),
        pulseCount: find.byKey(const ValueKey('current_location_pulse')).evaluate().length,
      ),
      (loadingIndicatorCount: 1, preservesLoadingIndicatorState: true, pulseCount: 1),
    );
    await tester.pump(const Duration(milliseconds: 25));
  });

  testWidgets('when permission is granted, it should resolve the region for display without selecting it', (
    tester,
  ) async {
    final service = buildService(permissionStatuses: [DeviceLocationPermissionStatus.whileInUse]);
    DeviceLocationAddress? selectedAddress;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (address) => selectedAddress = address);

    expect(
      <Object?>[find.text('Pinheiros, São Paulo').evaluate().length, selectedAddress, service.requestPermissionValues],
      <Object?>[
        1,
        null,
        [false],
      ],
    );
  });

  testWidgets('when tapped before resolving, it should request permission and report the resolved address', (
    tester,
  ) async {
    final service = buildService();
    DeviceLocationAddress? selectedAddress;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (address) => selectedAddress = address);

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pumpAndSettle();

    expect(
      <Object?>[selectedAddress, service.requestPermissionValues],
      <Object?>[
        neighborhoodAddress,
        [true],
      ],
    );
  });

  testWidgets('when tapped during a retry delay, it should keep one lookup and report one selection', (tester) async {
    final service = buildService(
      addressErrors: [const DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable), null],
    );
    var selectionCount = 0;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) => selectionCount += 1);

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await tester.tap(find.byType(UseCurrentLocationButton), warnIfMissed: false);
    await pumpRetryDelays(tester, retryCount: 1);

    expect(
      (selectionCount: selectionCount, addressRequestCount: service.addressRequestCount),
      (selectionCount: 1, addressRequestCount: 2),
    );
  });

  testWidgets('when tapped repeatedly during lookup, it should share one request and report one selection', (
    tester,
  ) async {
    final addressCompleter = Completer<DeviceLocationAddress>();
    final service = buildService(addressCompleter: addressCompleter);
    var selectionCount = 0;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) => selectionCount += 1);

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await tester.tap(find.byType(UseCurrentLocationButton), warnIfMissed: false);
    addressCompleter.complete(neighborhoodAddress);
    await tester.pumpAndSettle();

    expect(
      (selectionCount: selectionCount, addressRequestCount: service.addressRequestCount),
      (selectionCount: 1, addressRequestCount: 1),
    );
  });

  testWidgets('when loading resolves, it should keep both descriptions aligned during the fade', (tester) async {
    final addressCompleter = Completer<DeviceLocationAddress>();
    final service = buildService(addressCompleter: addressCompleter);
    await pumpButton(
      tester,
      deviceLocationService: service,
      onRequestedToUse: (_) {},
      mediaQueryData: const MediaQueryData(disableAnimations: false),
    );
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    addressCompleter.complete(neighborhoodAddress);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 175));
    final loadingDescriptionHeight = tester.getTopLeft(find.text(i18n.useCurrentLocationButton.loading)).dy;
    final resolvedDescriptionHeight = tester.getTopLeft(find.text('Pinheiros, São Paulo')).dy;

    expect(resolvedDescriptionHeight, loadingDescriptionHeight);

    await tester.pump(const Duration(milliseconds: 175));
  });

  for (final testCase in <({DeviceLocationAddress address, String expected, String name})>[
    (name: 'neighborhood and city', address: neighborhoodAddress, expected: 'Pinheiros, São Paulo'),
    (
      name: 'neighborhood',
      address: const DeviceLocationAddress(coordinates: coordinates, neighborhood: 'Pinheiros'),
      expected: 'Pinheiros',
    ),
    (
      name: 'city',
      address: const DeviceLocationAddress(coordinates: coordinates, city: 'São Paulo'),
      expected: 'São Paulo',
    ),
    (
      name: 'street',
      address: const DeviceLocationAddress(coordinates: coordinates, street: 'Rua dos Pinheiros', name: 'Mercado'),
      expected: 'Rua dos Pinheiros',
    ),
  ]) {
    testWidgets('when ${testCase.name} is the preferred available component, it should show that label', (
      tester,
    ) async {
      final service = buildService(
        address: testCase.address,
        permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
      );
      await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

      expect(find.text(testCase.expected), findsOneWidget);
    });
  }

  testWidgets('when no preferred address component is available, it should show the detection fallback', (
    tester,
  ) async {
    final service = buildService(
      address: const DeviceLocationAddress(coordinates: coordinates, name: 'Mercado Municipal', country: 'Brasil'),
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
    );
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    expect(find.text(i18n.useCurrentLocationButton.unavailable), findsOneWidget);
  });

  for (final reason in <DeviceLocationExceptionReason>[
    DeviceLocationExceptionReason.operationUnavailable,
    DeviceLocationExceptionReason.coordinatesUnavailable,
    DeviceLocationExceptionReason.configurationMissing,
    DeviceLocationExceptionReason.unsupportedPlatform,
  ]) {
    testWidgets('when address lookup fails with $reason, it should show the detection fallback', (tester) async {
      final service = buildService(addressError: DeviceLocationException(reason));
      await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

      await tester.tap(find.byType(UseCurrentLocationButton));
      await tester.pump();
      await pumpRetryDelays(tester);

      expect(find.text(i18n.useCurrentLocationButton.unavailable), findsOneWidget);
    });
  }

  testWidgets('when the address resolves asynchronously, semantics should announce the selected label', (tester) async {
    final semanticsHandle = tester.ensureSemantics();
    final service = buildService(permissionStatuses: [DeviceLocationPermissionStatus.whileInUse]);
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    final semantics = tester.getSemantics(find.byType(UseCurrentLocationButton));
    semanticsHandle.dispose();

    expect(
      (value: semantics.value, isLiveRegion: semantics.flagsCollection.isLiveRegion),
      (value: 'Pinheiros, São Paulo', isLiveRegion: true),
    );
  });

  testWidgets('when location services are disabled, it should show the service recovery guidance', (tester) async {
    final service = buildService(
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.servicesDisabled),
    );
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);

    expect(find.text(i18n.useCurrentLocationButton.servicesDisabled), findsOneWidget);
  });

  testWidgets('when permission is restricted, it should show policy guidance without requesting an address', (
    tester,
  ) async {
    final service = buildService(permissionStatuses: [DeviceLocationPermissionStatus.restricted]);
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pumpAndSettle();

    expect(
      (
        restrictedCount: find.text(i18n.useCurrentLocationButton.restricted).evaluate().length,
        addressRequestCount: service.addressRequestCount,
      ),
      (restrictedCount: 1, addressRequestCount: 0),
    );
  });

  testWidgets('when permission is permanently denied, it should explain the settings recovery', (tester) async {
    final service = buildService(
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);

    expect(
      (
        sheetCount: find.text(i18n.useCurrentLocationButton.permissionSheet.description).evaluate().length,
        addressRequestCount: service.addressRequestCount,
      ),
      (sheetCount: 1, addressRequestCount: 1),
    );
  });

  testWidgets('when the permanent-denial sheet is closed, it should not open settings', (tester) async {
    final service = buildService(
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);

    await tester.tap(find.byKey(const Key('mateo_bottom_sheet_close_button')));
    await tester.pumpAndSettle();

    expect(service.openLocationSettingsRequestCount, 0);
  });

  testWidgets('when settings is selected, it should wait for the permission sheet to close before opening it', (
    tester,
  ) async {
    final service = buildService(
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    await pumpButton(
      tester,
      deviceLocationService: service,
      onRequestedToUse: (_) {},
      mediaQueryData: const MediaQueryData(disableAnimations: false),
    );
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);

    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pump();
    final sheetCountWhileClosing = find
        .byKey(const ValueKey('current_location_permission_sheet_title'))
        .evaluate()
        .length;
    final settingsCountWhileClosing = service.openLocationSettingsRequestCount;
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();

    expect(
      (
        sheetCountWhileClosing: sheetCountWhileClosing,
        settingsCountWhileClosing: settingsCountWhileClosing,
        sheetCountAfterClosing: find.byKey(const ValueKey('current_location_permission_sheet_title')).evaluate().length,
        settingsCountAfterClosing: service.openLocationSettingsRequestCount,
      ),
      (
        sheetCountWhileClosing: 1,
        settingsCountWhileClosing: 0,
        sheetCountAfterClosing: 0,
        settingsCountAfterClosing: 1,
      ),
    );
  });

  testWidgets('when settings navigation is rejected, it should show localized recovery feedback', (tester) async {
    final service = buildService(
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
      openLocationSettingsResult: false,
    );
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);

    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pumpAndSettle();

    expect(find.text(i18n.useCurrentLocationButton.settingsOpenError), findsOneWidget);
  });

  testWidgets('when permission is granted in settings, resuming should finish the original selection request', (
    tester,
  ) async {
    final service = buildService(
      permissionStatuses: [DeviceLocationPermissionStatus.denied, DeviceLocationPermissionStatus.whileInUse],
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    DeviceLocationAddress? selectedAddress;
    var selectionCount = 0;
    await pumpButton(
      tester,
      deviceLocationService: service,
      onRequestedToUse: (address) {
        selectedAddress = address;
        selectionCount += 1;
      },
    );
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);
    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pumpAndSettle();
    service.addressError = null;

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      (
        selectedAddress: selectedAddress,
        selectionCount: selectionCount,
        sheetCount: find.byKey(const ValueKey('current_location_permission_sheet_title')).evaluate().length,
      ),
      (selectedAddress: neighborhoodAddress, selectionCount: 1, sheetCount: 0),
    );
  });

  testWidgets('when every lookup attempt fails, it should expose only the final failure state', (tester) async {
    final service = buildService(
      addressErrors: [
        const DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable),
        const DeviceLocationException(DeviceLocationExceptionReason.coordinatesUnavailable),
        const DeviceLocationException(DeviceLocationExceptionReason.servicesDisabled),
      ],
    );
    DeviceLocationAddress? selectedAddress;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (address) => selectedAddress = address);

    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);

    expect(
      (
        selectedAddress: selectedAddress,
        addressRequestCount: service.addressRequestCount,
        finalFailureCount: find.text(i18n.useCurrentLocationButton.servicesDisabled).evaluate().length,
      ),
      (selectedAddress: null, addressRequestCount: 3, finalFailureCount: 1),
    );
  });

  testWidgets('when a Settings permission prompt is denied, it should show the sheet again without retrying', (
    tester,
  ) async {
    final service = buildService(
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    DeviceLocationAddress? selectedAddress;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (address) => selectedAddress = address);
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);
    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pumpAndSettle();
    service
      ..addressError = const DeviceLocationException(DeviceLocationExceptionReason.permissionDenied)
      ..addressRequestCount = 0
      ..requestPermissionValues.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(seconds: 1));

    expect(
      <Object?>[
        selectedAddress,
        find.text(i18n.useCurrentLocationButton.permissionSheet.description).evaluate().length,
        service.addressRequestCount,
        service.requestPermissionValues,
      ],
      <Object?>[
        null,
        1,
        1,
        [true],
      ],
    );
  });

  testWidgets('when Settings changes permission to ask, resuming should show the native request and select', (
    tester,
  ) async {
    final service = buildService(
      permissionStatuses: [DeviceLocationPermissionStatus.denied, DeviceLocationPermissionStatus.notDetermined],
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    DeviceLocationAddress? selectedAddress;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (address) => selectedAddress = address);
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);
    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pumpAndSettle();
    service
      ..addressError = null
      ..addressRequestCount = 0
      ..requestPermissionValues.clear();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      <Object?>[selectedAddress, service.addressRequestCount, service.requestPermissionValues],
      <Object?>[
        neighborhoodAddress,
        1,
        [true],
      ],
    );
  });

  testWidgets('when a Settings recovery exhausts its retries, the reopened sheet should start another cycle', (
    tester,
  ) async {
    final service = buildService(
      permissionStatuses: [DeviceLocationPermissionStatus.denied, DeviceLocationPermissionStatus.whileInUse],
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionPermanentlyDenied),
    );
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (_) {});
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();
    await pumpRetryDelays(tester);
    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pumpAndSettle();
    service.addressError = const DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await pumpRetryDelays(tester);
    final reopenedSheetCount = find.text(i18n.useCurrentLocationButton.permissionSheet.description).evaluate().length;
    await tester.tap(find.byKey(const ValueKey('current_location_permission_sheet_settings_button')));
    await tester.pumpAndSettle();

    expect(
      (reopenedSheetCount: reopenedSheetCount, settingsOpenCount: service.openLocationSettingsRequestCount),
      (reopenedSheetCount: 1, settingsOpenCount: 2),
    );
  });

  testWidgets('when disposed during lookup, it should not report a selection or framework exception', (tester) async {
    final addressCompleter = Completer<DeviceLocationAddress>();
    final service = buildService(addressCompleter: addressCompleter);
    DeviceLocationAddress? selectedAddress;
    await pumpButton(tester, deviceLocationService: service, onRequestedToUse: (address) => selectedAddress = address);
    await tester.tap(find.byType(UseCurrentLocationButton));
    await tester.pump();

    await tester.pumpWidget(const SizedBox.shrink());
    addressCompleter.complete(neighborhoodAddress);
    await tester.pumpAndSettle();

    expect(
      (selectedAddress: selectedAddress, exception: tester.takeException()),
      (selectedAddress: null, exception: null),
    );
  });

  testWidgets('when the current-location button is shown in dark mode, it should report the unsupported theme', (
    tester,
  ) async {
    final service = buildService();
    await tester.pumpWidget(
      TestApp(
        providerOverrides: [deviceLocationProvider.overrideWithValue(service)],
        child: Builder(
          builder: (context) => Theme(
            data: Theme.of(context).copyWith(brightness: Brightness.dark),
            child: UseCurrentLocationButton(onRequestedToUse: (_) {}),
          ),
        ),
      ),
    );

    expect(
      tester.takeException(),
      isA<UnsupportedError>().having(
        (error) => error.message,
        'message',
        'CurrentLocationButton does not support dark mode.',
      ),
    );
  });
}
