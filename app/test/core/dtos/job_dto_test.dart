import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/dtos/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobDto', () {
    test('when parsing a detailed job, it should map the job id', () {
      final job = JobDto.fixture().copyWith(jobId: 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');

      expect(job.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when parsing a detailed job, it should map the job status', () {
      final job = JobDto.fixture().copyWith(status: JobStatus.active);

      expect(job.status, JobStatus.active);
    });

    test('when parsing a detailed job, it should map the job type', () {
      final job = JobDto.fixture().copyWith(type: JobType.individual);

      expect(job.type, JobType.individual);
    });

    test(
      'when parsing a detailed job, it should map the created timestamp',
      () {
        final job = JobDto.fixture().copyWith(createdAt: DateTime.parse('2026-06-06T00:36:46.623Z'));

        expect(job.createdAt, DateTime.parse('2026-06-06T00:36:46.623Z'));
      },
    );

    test('when parsing an unknown status, it should use the unknown value', () {
      final job = JobDto.fromJson({
        ...JobDto.fixture().toJson(),
        'status': 'PAUSED',
      });

      expect(job.status, JobStatus.unknown);
    });
  });
}
