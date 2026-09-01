import 'package:oh_my_flutter/oh_my_flutter.dart';

extension DeviceLocationAddressExtension on DeviceLocationAddress {
  String? jobLocation() {
    return switch ((neighborhood, city)) {
      (final neighborhood?, final city?) => '$neighborhood, $city',
      (final neighborhood?, null) => neighborhood,
      (null, final city?) => city,
      (null, null) => street,
    };
  }
}
