import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:flutter/foundation.dart';

@immutable
class JobData {
  const JobData({required this.job});

  final JobDto job;

  JobData copyWith({JobDto? job}) {
    return JobData(job: job ?? this.job);
  }
}
