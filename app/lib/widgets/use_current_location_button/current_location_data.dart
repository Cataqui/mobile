import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';

part 'current_location_data.freezed.dart';

@freezed
sealed class CurrentLocationData with _$CurrentLocationData {
  const factory CurrentLocationData.permission({required DeviceLocationPermissionStatus status}) =
      CurrentLocationPermissionData;

  const factory CurrentLocationData.resolved({required DeviceLocationAddress address}) = ResolvedCurrentLocationData;

  const factory CurrentLocationData.failure({required DeviceLocationExceptionReason reason}) =
      FailedCurrentLocationData;
}
