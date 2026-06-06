import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:flutter_test/flutter_test.dart';

import 'dto_json_fixtures.dart';

void main() {
  group('ApiEnvelopeDto', () {
    test(
      'when parsing a job envelope, it should map the requested resource',
      () {
        final envelope = ApiEnvelopeDto<JobDto>.fromJson(
          jobEnvelopeJson,
          (json) => JobDto.fromJson(json! as Map<String, Object?>),
        );

        expect(envelope.data.title, 'Mock: ajudante para descarregar caminhão');
      },
    );

    test('when parsing a job envelope, it should map the request id', () {
      final envelope = ApiEnvelopeDto<JobDto>.fromJson(
        jobEnvelopeJson,
        (json) => JobDto.fromJson(json! as Map<String, Object?>),
      );

      expect(envelope.requestId, '7a037a1d-3164-42f0-b4bf-18f3f47d3c1d');
    });

    test('when parsing a feed envelope, it should map the list resource', () {
      final envelope = ApiEnvelopeDto<List<FeedJobDto>>.fromJson(
        feedEnvelopeJson,
        (json) => (json! as List<Object?>)
            .map((item) => FeedJobDto.fromJson(item! as Map<String, Object?>))
            .toList(),
      );

      expect(envelope.data.first.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when parsing a feed envelope, it should map pagination', () {
      final envelope = ApiEnvelopeDto<List<FeedJobDto>>.fromJson(
        feedEnvelopeJson,
        (json) => (json! as List<Object?>)
            .map((item) => FeedJobDto.fromJson(item! as Map<String, Object?>))
            .toList(),
      );

      expect(envelope.pagination?.nextCursor, 'next-feed-cursor');
    });
  });
}
