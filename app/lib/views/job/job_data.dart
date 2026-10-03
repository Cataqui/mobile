import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:flutter/foundation.dart';

@immutable
class JobData {
  const JobData({required this.job});

  final PublicJobDto job;

  JobData copyWith({PublicJobDto? job}) {
    return JobData(job: job ?? this.job);
  }
}
