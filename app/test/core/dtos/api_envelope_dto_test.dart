import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/job_dto.dart';
import 'package:flutter_test/flutter_test.dart';

const _jobEnvelopeJson = <String, Object?>{
  'data': <String, Object?>{
    'job_id': 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    'title': 'Mock: ajudante para descarregar caminhão',
    'description': 'Mock job description.',
    'contact': <String, Object?>{
      'name': 'Cataqui Teste',
      'phone_number': '+5511999999999',
      'contact_method': 'WHATSAPP',
    },
    'location': <String, Object?>{
      'street': 'Rua das Flores, 123',
      'neighborhood': 'Centro',
      'city': 'São Paulo',
      'state': 'SP',
      'country': 'BR',
      'latitude': -23.556391,
      'longitude': -46.844076,
      'area_radius': 2000,
    },
    'category': <String, Object?>{
      'category_id': 'afdfd9b2-203d-4528-8a1c-82b6b139039b',
      'name': 'Outro',
      'slug': 'other',
    },
    'payment': <String, Object?>{
      'type': 'FIXED',
      'min_amount': 120,
      'amount_period': 'SINGLE',
      'currency': 'BRL',
    },
    'status': 'ACTIVE',
    'type': 'INDIVIDUAL',
    'created_at': '2026-06-06T00:36:46.623Z',
    'updated_at': '2026-06-06T00:36:46.623Z',
  },
  'request_id': '7a037a1d-3164-42f0-b4bf-18f3f47d3c1d',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/jobs/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
};

const _feedEnvelopeJson = <String, Object?>{
  'data': <Map<String, Object?>>[
    <String, Object?>{
      'job_id': 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
      'title': 'Mock: ajudante para descarregar caminhão',
      'created_at': '2026-06-06T00:36:46.623Z',
      'description_summary': 'Experiente em atendimento ao cliente.',
      'payment': <String, Object?>{
        'type': 'FIXED',
        'min_amount': 120,
        'amount_period': 'SINGLE',
        'currency': 'BRL',
      },
      'location': <String, Object?>{
        'neighborhood': 'Centro',
        'city': 'São Paulo',
        'state': 'SP',
        'latitude': -23.556391,
        'longitude': -46.844076,
        'area_radius': 2000,
      },
    },
  ],
  'request_id': '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/feed/jobs',
  'pagination': <String, Object?>{
    'has_more': true,
    'next_cursor': 'next-feed-cursor',
  },
};

void main() {
  group('ApiEnvelopeDto', () {
    test(
      'when parsing a job envelope, it should map the requested resource',
      () {
        final envelope = ApiEnvelopeDto<JobDto>.fromJson(
          _jobEnvelopeJson,
          (json) => JobDto.fromJson(json! as Map<String, Object?>),
        );

        expect(envelope.data.title, 'Mock: ajudante para descarregar caminhão');
      },
    );

    test('when parsing a job envelope, it should map the request id', () {
      final envelope = ApiEnvelopeDto<JobDto>.fromJson(
        _jobEnvelopeJson,
        (json) => JobDto.fromJson(json! as Map<String, Object?>),
      );

      expect(envelope.requestId, '7a037a1d-3164-42f0-b4bf-18f3f47d3c1d');
    });

    test('when parsing a feed envelope, it should map the list resource', () {
      final envelope = ApiEnvelopeDto<List<FeedJobDto>>.fromJson(
        _feedEnvelopeJson,
        (json) => (json! as List<Object?>)
            .map((item) => FeedJobDto.fromJson(item! as Map<String, Object?>))
            .toList(),
      );

      expect(envelope.data.first.jobId, 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502');
    });

    test('when parsing a feed envelope, it should map pagination', () {
      final envelope = ApiEnvelopeDto<List<FeedJobDto>>.fromJson(
        _feedEnvelopeJson,
        (json) => (json! as List<Object?>)
            .map((item) => FeedJobDto.fromJson(item! as Map<String, Object?>))
            .toList(),
      );

      expect(envelope.pagination?.nextCursor, 'next-feed-cursor');
    });
  });
}
