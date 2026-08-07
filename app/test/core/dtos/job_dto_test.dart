import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('JobDto', () {
    test('when category is absent, it should parse the detailed job', () {
      final json = JobDto.fixture().copyWith(jobId: 'job-without-category').toJson()..remove('category');
      final job = JobDto.fromJson(json);

      expect(job.jobId, 'job-without-category');
    });

    test('when parsing a detailed job, it should map the job id', () {
      final job = JobDto.fromJson({...JobDto.fixture().toJson(), 'jobId': 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502'});

      expect(job.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when parsing a detailed job, it should map the job status', () {
      final job = JobDto.fromJson({...JobDto.fixture().toJson(), 'status': 'ACTIVE'});

      expect(job.status, JobStatus.active);
    });

    test('when parsing a detailed job, it should map the job type', () {
      final job = JobDto.fromJson({...JobDto.fixture().toJson(), 'type': 'INDIVIDUAL'});

      expect(job.type, JobType.individual);
    });

    test('when parsing a detailed job, it should map the created timestamp', () {
      final job = JobDto.fromJson({...JobDto.fixture().toJson(), 'createdAt': '2026-06-06T00:36:46.623Z'});

      expect(job.createdAt, DateTime.parse('2026-06-06T00:36:46.623Z'));
    });

    test('when parsing an unknown status, it should use the unknown value', () {
      final job = JobDto.fromJson({...JobDto.fixture().toJson(), 'status': 'PAUSED'});

      expect(job.status, JobStatus.unknown);
    });

    test('when serializing a detailed job, it should use camelCase keys', () {
      final json = JobDto.fixture().toJson();

      expect(json.keys, containsAll(<String>['jobId', 'contactReference', 'createdAt', 'updatedAt']));
    });
  });
}
