import 'dart:isolate';

import 'package:cataqui_app/core/dtos/contact_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:flutter/foundation.dart';

@immutable
class MyPostData {
  const MyPostData({required this.detail, required this.contactLabel});

  factory MyPostData.fromDetail(UserJobDto detail) =>
      MyPostData(detail: detail, contactLabel: _formatContact(detail.contact));

  final UserJobDto detail;
  final String? contactLabel;

  static Future<MyPostData> prepare(UserJobDto detail) async {
    final contact = detail.contact;
    if (contact == null || contact.identifier.trim().isEmpty || contact.method == .unknown) {
      return MyPostData.fromDetail(detail);
    }

    final method = contact.method;
    final identifier = contact.identifier;
    final contactLabel = await Isolate.run(() => method.displayIdentifier(identifier));
    return MyPostData(detail: detail, contactLabel: contactLabel);
  }

  static String? _formatContact(ContactDto? contact) {
    if (contact == null || contact.identifier.trim().isEmpty) return null;
    return switch (contact.method) {
      .unknown => contact.identifier,
      .whatsapp || .phoneCall => contact.method.displayIdentifier(contact.identifier),
    };
  }
}
