import 'package:freezed_annotation/freezed_annotation.dart';

enum JobStatus {
  @JsonValue('ACTIVE')
  active,
  @JsonValue('CLOSED')
  closed,
  unknown,
}

enum JobType {
  @JsonValue('INDIVIDUAL')
  individual,
  @JsonValue('EMPLOYMENT')
  employment,
  @JsonValue('CONTRACTOR')
  contractor,
  unknown,
}

enum JobContactMethod {
  @JsonValue('WHATSAPP')
  whatsapp,
  @JsonValue('PHONE_CALL')
  phoneCall,
  unknown,
}

enum JobPaymentAmountPeriod {
  @JsonValue('SINGLE')
  single,
  @JsonValue('DAILY')
  daily,
  @JsonValue('WEEKLY')
  weekly,
  @JsonValue('MONTHLY')
  monthly,
  @JsonValue('YEARLY')
  yearly,
  @JsonValue('HOURLY')
  hourly,
  unknown,
}

enum JobPaymentType {
  @JsonValue('FIXED')
  fixed,
  @JsonValue('RANGE')
  range,
  @JsonValue('FLEXIBLE')
  flexible,
  @JsonValue('OTHER')
  other,
  unknown,
}
