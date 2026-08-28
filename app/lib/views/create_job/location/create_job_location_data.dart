import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_job_location_data.freezed.dart';

@freezed
abstract class CreateJobLocationData with _$CreateJobLocationData {
  const factory CreateJobLocationData({
    @Default(AsyncData<AddressSearchResponseDto?>(null)) AsyncValue<AddressSearchResponseDto?> addressSearch,
  }) = _CreateJobLocationData;
}
