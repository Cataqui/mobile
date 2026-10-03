import 'package:freezed_annotation/freezed_annotation.dart';

@JsonEnum(valueField: 'jsonValue')
enum JobStatus {
  active('ACTIVE'),
  archived('ARCHIVED'),
  unknown('unknown');

  const JobStatus(this.jsonValue);

  final String jsonValue;
}
