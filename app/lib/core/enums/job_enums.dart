import 'package:flutter/widgets.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:mateo_mobile/mateo_mobile.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

@JsonEnum(valueField: 'jsonValue')
enum JobStatus {
  active('ACTIVE'),
  archived('ARCHIVED'),
  unknown('unknown');

  const JobStatus(this.jsonValue);

  final String jsonValue;
}

@JsonEnum(valueField: 'jsonValue')
enum JobContactMethod {
  whatsapp('WHATSAPP'),
  phoneCall('PHONE_CALL'),
  unknown('unknown');

  const JobContactMethod(this.jsonValue);

  final String jsonValue;

  Widget icon({double? size, Color? color, Color? backgroundColor}) {
    return switch (this) {
      JobContactMethod.whatsapp => MateoIcon(.whatsapp, size: size, color: color, backgroundColor: backgroundColor),
      JobContactMethod.phoneCall => MateoIcon(.phone, size: size, color: color, backgroundColor: backgroundColor),
      JobContactMethod.unknown => MateoIcon(.circleBlock, size: size, color: color, backgroundColor: backgroundColor),
    };
  }

  String displayIdentifier(String identifier) {
    return switch (this) {
      JobContactMethod.whatsapp => Whatsapp(identifier).toDisplayString(),
      JobContactMethod.phoneCall => PhoneNumber.parse(identifier).toDisplayString(),
      JobContactMethod.unknown => throw UnsupportedError('Unknown job contact method.'),
    };
  }
}
