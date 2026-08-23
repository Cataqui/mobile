import 'package:json_annotation/json_annotation.dart';

@JsonEnum(valueField: 'value')
enum MicroserviceAccessTokenType {
  bearer('Bearer');

  const MicroserviceAccessTokenType(this.value);

  final String value;
}
