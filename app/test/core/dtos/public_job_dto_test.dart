import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PublicJobDto', () {
    test('when category is absent, it should parse the detailed job', () {
      final json = PublicJobDto.fixture().copyWith(jobId: 'job-without-category').toJson()..remove('category');
      final job = PublicJobDto.fromJson(json);

      expect(job.jobId, 'job-without-category');
    });

    test('when parsing a detailed job, it should map the job id', () {
      final job = PublicJobDto.fromJson({
        ...PublicJobDto.fixture().toJson(),
        'jobId': 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
      });

      expect(job.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when parsing a detailed job, it should map the backend description summary', () {
      final job = PublicJobDto.fromJson({
        ...PublicJobDto.fixture().toJson(),
        'descriptionSummary': 'Turno curto no centro com pagamento no mesmo dia.',
      });

      expect(job.descriptionSummary, 'Turno curto no centro com pagamento no mesmo dia.');
    });

    test('when parsing a detailed job, it should map the job status', () {
      final job = PublicJobDto.fromJson({...PublicJobDto.fixture().toJson(), 'status': 'ACTIVE'});

      expect(job.status, JobStatus.active);
    });

    test('when parsing an archived detailed job, it should map the archived status', () {
      final job = PublicJobDto.fromJson({...PublicJobDto.fixture().toJson(), 'status': 'ARCHIVED'});

      expect(job.status, JobStatus.archived);
    });

    test('when parsing a detailed job, it should map the created timestamp', () {
      final job = PublicJobDto.fromJson({...PublicJobDto.fixture().toJson(), 'createdAt': '2026-06-06T00:36:46.623Z'});

      expect(job.createdAt, DateTime.parse('2026-06-06T00:36:46.623Z'));
    });

    test('when parsing an unknown status, it should use the unknown value', () {
      final job = PublicJobDto.fromJson({...PublicJobDto.fixture().toJson(), 'status': 'PAUSED'});

      expect(job.status, JobStatus.unknown);
    });

    test('when serializing a detailed job, it should use camelCase keys', () {
      final json = PublicJobDto.fixture().toJson();

      expect(
        json.keys,
        containsAll(<String>['jobId', 'descriptionSummary', 'contactReference', 'createdAt', 'updatedAt']),
      );
    });
  });
}
