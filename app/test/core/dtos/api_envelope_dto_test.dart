import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiEnvelopeDto', () {
    test('when creating a job envelope from fixture, it should map the requested resource', () {
      final envelope = ApiEnvelopeDto<JobDto>(
        data: JobDto.fixture(),
        requestId: 'req_001',
        timestamp: DateTime(2026, 6, 6, 0, 37, 46),
        endpoint: '/v1/jobs/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
      );

      expect(envelope.data.title, JobDto.fixture().title);
    });

    test('when creating a job envelope from fixture, it should map the request id', () {
      final envelope = ApiEnvelopeDto<JobDto>(
        data: JobDto.fixture(),
        requestId: 'req_001',
        timestamp: DateTime(2026, 6, 6, 0, 37, 46),
        endpoint: '/v1/jobs/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
      );

      expect(envelope.requestId, 'req_001');
    });

    test('when creating a feed envelope from fixture, it should map the list resource', () {
      final envelope = ApiEnvelopeDto<List<FeedJobDto>>(
        data: [FeedJobDto.fixture()],
        requestId: 'req_002',
        timestamp: DateTime(2026, 6, 6, 0, 37, 46),
        endpoint: '/v1/feed',
        pagination: ApiPaginationDto.fixture(),
      );

      expect(envelope.data.first.jobId, FeedJobDto.fixture().jobId);
    });

    test('when creating a feed envelope from fixture, it should map pagination', () {
      final envelope = ApiEnvelopeDto<List<FeedJobDto>>(
        data: [FeedJobDto.fixture()],
        requestId: 'req_002',
        timestamp: DateTime(2026, 6, 6, 0, 37, 46),
        endpoint: '/v1/feed',
        pagination: ApiPaginationDto.fixture(),
      );

      expect(envelope.pagination?.nextCursor, ApiPaginationDto.fixture().nextCursor);
    });

    test('when serializing an API envelope, it should use camelCase keys', () {
      final envelope = ApiEnvelopeDto<JobDto>.fixture(data: JobDto.fixture());

      expect(envelope.toJson((job) => job.toJson()), containsPair('requestId', 'req-fixture'));
    });
  });
}
