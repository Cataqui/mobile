import 'package:cataqui_app/core/extensions/device_location_address_extension.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

void main() {
  test('when no preferred address component is available, it should return null', () {
    const address = DeviceLocationAddress(
      coordinates: DeviceLocationCoordinates(latitude: -23.561684, longitude: -46.655981, accuracy: 18),
      name: 'Mercado Municipal',
      country: 'Brasil',
    );

    expect(address.jobLocation(), isNull);
  });
}
