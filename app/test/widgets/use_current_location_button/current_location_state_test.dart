import 'dart:async';

import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/widgets/use_current_location_button/current_location_data.dart';
import 'package:cataqui_app/widgets/use_current_location_button/current_location_state.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

import 'fake_device_location.dart';

void main() {
  const coordinates = DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18);
  const address = DeviceLocationAddress(coordinates: coordinates, neighborhood: 'Pinheiros');

  ProviderContainer buildContainer(FakeDeviceLocation deviceLocation) {
    return ProviderContainer.test(overrides: [deviceLocationProvider.overrideWithValue(deviceLocation)])
      ..listen(currentLocationStateProvider, (_, _) {});
  }

  test('when instantiated, it should expose loading before permission resolution completes', () {
    final container = buildContainer(
      FakeDeviceLocation(address: address, permissionStatuses: [DeviceLocationPermissionStatus.denied]),
    );
    addTearDown(container.dispose);

    expect(container.read(currentLocationStateProvider), isA<AsyncLoading<CurrentLocationData>>());
  });

  test('when initial permission is denied, it should resolve permission data without requesting an address', () async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);

    final data = await container.read(currentLocationStateProvider.future);

    expect(
      (data: data, addressRequestCount: deviceLocation.addressRequestCount),
      (
        data: const CurrentLocationData.permission(status: DeviceLocationPermissionStatus.denied),
        addressRequestCount: 0,
      ),
    );
  });

  test('when its last listener is removed, it should keep the resolved location alive', () async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
    );
    final container = ProviderContainer.test(overrides: [deviceLocationProvider.overrideWithValue(deviceLocation)]);
    addTearDown(container.dispose);
    final subscription = container.listen(currentLocationStateProvider, (_, _) {});
    await container.read(currentLocationStateProvider.future);

    subscription.close();
    await Future<void>.delayed(Duration.zero);
    await container.read(currentLocationStateProvider.notifier).requestCurrentAddress();

    expect(deviceLocation.addressRequestCount, 1);
  });

  test('when initial permission is granted, it should resolve automatically in the active app locale', () async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);

    final data = await container.read(currentLocationStateProvider.future);

    expect(
      (
        data: data,
        requestPermissionValues: deviceLocation.requestPermissionValues.join(','),
        locale: deviceLocation.lastRequestedLocale,
      ),
      (
        data: const CurrentLocationData.resolved(address: address),
        requestPermissionValues: 'false',
        locale: const Locale('pt', 'BR'),
      ),
    );
  });

  for (final successfulAttempt in [2, 3]) {
    testWidgets('when automatic resolution succeeds on attempt $successfulAttempt, it should stop retrying', (
      tester,
    ) async {
      final deviceLocation = FakeDeviceLocation(
        address: address,
        permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
        addressErrors: [
          for (var attempt = 1; attempt < successfulAttempt; attempt += 1)
            const DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable),
          null,
        ],
      );
      final container = buildContainer(deviceLocation);
      addTearDown(container.dispose);

      final future = container.read(currentLocationStateProvider.future);
      for (var retry = 1; retry < successfulAttempt; retry += 1) {
        await tester.pump(const Duration(milliseconds: 500));
      }
      final data = await future;
      container.dispose();

      expect(
        (data: data, requestCount: deviceLocation.addressRequestCount),
        (data: const CurrentLocationData.resolved(address: address), requestCount: successfulAttempt),
      );
    });
  }

  testWidgets('when automatic resolution exhausts its attempts, it should expose only the final failure', (
    tester,
  ) async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
      addressErrors: const [
        DeviceLocationException(DeviceLocationExceptionReason.servicesDisabled),
        DeviceLocationException(DeviceLocationExceptionReason.coordinatesUnavailable),
        DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable),
      ],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);

    final future = container.read(currentLocationStateProvider.future);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));
    final data = await future;

    expect(
      (data: data, requestCount: deviceLocation.addressRequestCount),
      (
        data: const CurrentLocationData.failure(reason: DeviceLocationExceptionReason.operationUnavailable),
        requestCount: 3,
      ),
    );
  });

  testWidgets('when explicitly requested, it should prompt only on the first transient attempt', (tester) async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
      addressErrors: const [DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable), null],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    final future = container.read(currentLocationStateProvider.notifier).requestCurrentAddress();
    await tester.pump(const Duration(milliseconds: 500));
    final resolvedAddress = await future;
    container.dispose();

    expect(
      (address: resolvedAddress, requestPermissionValues: deviceLocation.requestPermissionValues.join(',')),
      (address: address, requestPermissionValues: 'true,false'),
    );
  });

  test('when an explicit permission prompt is denied, it should not retry', () async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.permissionDenied),
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    final resolvedAddress = await container.read(currentLocationStateProvider.notifier).requestCurrentAddress();

    expect(
      (
        address: resolvedAddress,
        requestCount: deviceLocation.addressRequestCount,
        data: container.read(currentLocationStateProvider).value,
      ),
      (
        address: null,
        requestCount: 1,
        data: const CurrentLocationData.permission(status: DeviceLocationPermissionStatus.denied),
      ),
    );
  });

  test('when an automatically resolved address is requested, it should reuse the resolved state', () async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    final resolvedAddress = await container.read(currentLocationStateProvider.notifier).requestCurrentAddress();

    expect(
      (address: resolvedAddress, requestCount: deviceLocation.addressRequestCount),
      (address: address, requestCount: 1),
    );
  });

  test('when a resolved address reaches 60 seconds, the next request should resolve it again', () async {
    var currentTime = DateTime.utc(2026, 8, 29, 12);
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
    );

    final requestCounts = await withClock(Clock(() => currentTime), () async {
      final container = buildContainer(deviceLocation);
      addTearDown(container.dispose);
      await container.read(currentLocationStateProvider.future);
      currentTime = currentTime.add(const Duration(seconds: 59));
      await container.read(currentLocationStateProvider.notifier).requestCurrentAddress();
      final requestCountBeforeExpiry = deviceLocation.addressRequestCount;
      currentTime = currentTime.add(const Duration(seconds: 1));
      await container.read(currentLocationStateProvider.notifier).requestCurrentAddress();

      return (beforeExpiry: requestCountBeforeExpiry, atExpiry: deviceLocation.addressRequestCount);
    });

    expect(requestCounts, (beforeExpiry: 1, atExpiry: 2));
  });

  testWidgets('when a resolved address expires after permission is denied, it should remove the stale address', (
    tester,
  ) async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse, DeviceLocationPermissionStatus.denied],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    await tester.pump(const Duration(seconds: 60));
    await tester.pump();

    expect(
      container.read(currentLocationStateProvider).value,
      const CurrentLocationData.permission(status: DeviceLocationPermissionStatus.denied),
    );
  });

  testWidgets('when a resolved address expires with permission granted, it should refresh automatically', (
    tester,
  ) async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    await tester.pump(const Duration(seconds: 60));
    await tester.pump();
    container.dispose();

    expect(deviceLocation.addressRequestCount, 2);
  });

  test('when explicit requests overlap, it should share one pending address lookup', () async {
    final addressCompleter = Completer<DeviceLocationAddress>();
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied],
      addressCompleter: addressCompleter,
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    final notifier = container.read(currentLocationStateProvider.notifier);
    final firstRequest = notifier.requestCurrentAddress();
    final secondRequest = notifier.requestCurrentAddress();
    addressCompleter.complete(address);
    final results = await Future.wait([firstRequest, secondRequest]);

    expect(
      (
        firstResultIsAddress: identical(results.first, address),
        secondResultIsAddress: identical(results.last, address),
        requestCount: deviceLocation.addressRequestCount,
      ),
      (firstResultIsAddress: true, secondResultIsAddress: true, requestCount: 1),
    );
  });

  testWidgets(
    'when Settings grants permission, recovery should resolve without prompting and retry transient failures',
    (tester) async {
      final deviceLocation = FakeDeviceLocation(
        address: address,
        permissionStatuses: [DeviceLocationPermissionStatus.denied, DeviceLocationPermissionStatus.whileInUse],
        addressErrors: const [DeviceLocationException(DeviceLocationExceptionReason.coordinatesUnavailable), null],
      );
      final container = buildContainer(deviceLocation);
      addTearDown(container.dispose);
      await container.read(currentLocationStateProvider.future);

      final future = container
          .read(currentLocationStateProvider.notifier)
          .resumeCurrentAddressRequestAfterSettingsPermission();
      await tester.pump(const Duration(milliseconds: 500));
      final resolvedAddress = await future;
      container.dispose();

      expect(
        (address: resolvedAddress, requestPermissionValues: deviceLocation.requestPermissionValues.join(',')),
        (address: address, requestPermissionValues: 'false,false'),
      );
    },
  );

  test('when Settings changes permission to ask, recovery should allow one native prompt', () async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.denied, DeviceLocationPermissionStatus.notDetermined],
    );
    final container = buildContainer(deviceLocation);
    addTearDown(container.dispose);
    await container.read(currentLocationStateProvider.future);

    final resolvedAddress = await container
        .read(currentLocationStateProvider.notifier)
        .resumeCurrentAddressRequestAfterSettingsPermission();

    expect(
      (address: resolvedAddress, requestPermissionValues: deviceLocation.requestPermissionValues.join(',')),
      (address: address, requestPermissionValues: 'true'),
    );
  });

  testWidgets('when disposed during a retry delay, it should stop before another attempt', (tester) async {
    final deviceLocation = FakeDeviceLocation(
      address: address,
      permissionStatuses: [DeviceLocationPermissionStatus.whileInUse],
      addressError: const DeviceLocationException(DeviceLocationExceptionReason.operationUnavailable),
    );
    final container = buildContainer(deviceLocation);
    await tester.pump();

    container.dispose();
    await tester.pump(const Duration(milliseconds: 500));

    expect(deviceLocation.addressRequestCount, 1);
  });
}
