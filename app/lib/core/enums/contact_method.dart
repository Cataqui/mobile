import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

@JsonEnum(valueField: 'jsonValue')
enum ContactMethod {
  whatsapp('WHATSAPP'),
  phoneCall('PHONE_CALL'),
  unknown('unknown');

  const ContactMethod(this.jsonValue);

  final String jsonValue;

  Widget icon({double? size, Color? color, Color? backgroundColor}) {
    return switch (this) {
      .whatsapp => MateoIcon(.whatsapp, size: size, color: color, backgroundColor: backgroundColor),
      .phoneCall => MateoIcon(.phone, size: size, color: color, backgroundColor: backgroundColor),
      .unknown => MateoIcon(.circleBlock, size: size, color: color, backgroundColor: backgroundColor),
    };
  }

  String displayIdentifier(String identifier) {
    return switch (this) {
      .whatsapp => Whatsapp(identifier).toDisplayString(),
      .phoneCall => PhoneNumber.parse(identifier).toDisplayString(),
      .unknown => throw UnsupportedError('Unknown job contact method.'),
    };
  }
}
