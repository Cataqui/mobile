import 'package:cataqui_app/core/dtos/account_metadata_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'welcome_data.freezed.dart';

@freezed
abstract class WelcomeData with _$WelcomeData {
  const factory WelcomeData({@Default(AsyncData<AccountMetadataDto?>(null)) AsyncValue<AccountMetadataDto?> metadata}) =
      _WelcomeData;
}
