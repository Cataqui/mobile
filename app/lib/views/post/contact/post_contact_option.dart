import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:flutter/foundation.dart';

@immutable
class PostContactOption {
  const PostContactOption({required this.contact, required this.displayIdentifier});

  final SavedContactDto contact;
  final String displayIdentifier;
}
