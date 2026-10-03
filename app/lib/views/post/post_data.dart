import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'post_data.freezed.dart';

@freezed
abstract class PostData with _$PostData {
  const factory PostData({
    ({String addressId, String sessionToken})? addressSelection,
    ({ContactMethod contactMethod, String identifier})? contact,
    String? descriptionText,
    ({double latitude, double longitude})? location,
    String? locationTitle,
    @Default(false) bool isPublishing,
  }) = _PostData;

  const PostData._();

  bool get canPublish {
    if (isPublishing) return false;
    final descriptionLength = descriptionText?.trim().length ?? 0;
    if (descriptionLength < 10 || descriptionLength > 10000) return false;
    if (contact == null) return false;
    if (locationTitle?.trim().isEmpty ?? true) return false;

    return addressSelection != null || location != null;
  }
}
