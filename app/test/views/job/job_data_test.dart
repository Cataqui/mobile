import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:cataqui_app/views/job/job_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobData', () {
    group('copyWith', () {
      test('when no arguments are passed, copyWith should preserve the job', () {
        final job = PublicJobDto.fixture();
        final data = JobData(job: job);

        final copy = data.copyWith();

        expect(copy.job, same(job));
      });

      test('when job is overridden, copyWith should use the new job', () {
        final job = PublicJobDto.fixture().copyWith(jobId: 'overridden-job-id');
        final data = JobData(job: PublicJobDto.fixture());

        final copy = data.copyWith(job: job);

        expect(copy.job.jobId, 'overridden-job-id');
      });
    });
  });
}
