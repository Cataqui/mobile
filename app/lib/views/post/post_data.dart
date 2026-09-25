import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_data.freezed.dart';

@freezed
abstract class PostData with _$PostData {
  const factory PostData({
    ({String addressId, String sessionToken})? addressSelection,
    ({JobContactMethod contactMethod, String identifier})? contact,
    String? descriptionText,
    ({double latitude, double longitude})? location,
    String? locationTitle,
    @Default(false) bool isPublishing,
  }) = _PostData;

  const PostData._();

  bool get canPublish {
    if (isPublishing) return false;
    if (descriptionText?.trim().isEmpty ?? true) return false;
    if (contact == null) return false;
    if (locationTitle?.trim().isEmpty ?? true) return false;

    return addressSelection != null || location != null;
  }
}
