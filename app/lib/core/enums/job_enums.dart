import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(valueField: 'jsonValue')
enum JobStatus {
  active('ACTIVE'),
  closed('CLOSED'),
  unknown('unknown');

  const JobStatus(this.jsonValue);

  final String jsonValue;
}

@JsonEnum(valueField: 'jsonValue')
enum JobType {
  individual('INDIVIDUAL'),
  employment('EMPLOYMENT'),
  contractor('CONTRACTOR'),
  unknown('unknown');

  const JobType(this.jsonValue);

  final String jsonValue;
}

@JsonEnum(valueField: 'jsonValue')
enum JobContactMethod {
  whatsapp('WHATSAPP'),
  phoneCall('PHONE_CALL'),
  unknown('unknown');

  const JobContactMethod(this.jsonValue);

  final String jsonValue;
}

@JsonEnum(valueField: 'jsonValue')
enum JobPaymentAmountPeriod {
  single('SINGLE'),
  daily('DAILY'),
  weekly('WEEKLY'),
  monthly('MONTHLY'),
  yearly('YEARLY'),
  hourly('HOURLY'),
  unknown('unknown');

  const JobPaymentAmountPeriod(this.jsonValue);

  final String jsonValue;
}

@JsonEnum(valueField: 'jsonValue')
enum JobPaymentType {
  fixed('FIXED'),
  range('RANGE'),
  flexible('FLEXIBLE'),
  other('OTHER');

  const JobPaymentType(this.jsonValue);

  final String jsonValue;
}
