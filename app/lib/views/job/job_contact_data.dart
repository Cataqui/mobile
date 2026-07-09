import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:flutter/foundation.dart';

@immutable
class JobContactData {
  const JobContactData({required this.contact});

  final JobContactDto contact;

  JobContactData copyWith({JobContactDto? contact}) {
    return JobContactData(contact: contact ?? this.contact);
  }
}
