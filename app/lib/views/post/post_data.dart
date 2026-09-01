import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_data.freezed.dart';

@freezed
abstract class PostData with _$PostData {
  const factory PostData({
    ({String addressId, String sessionToken})? addressSelection,
    String? descriptionText,
    ({double latitude, double longitude})? location,
    String? locationTitle,
    String? payment,
  }) = _PostData;
}
