const detailedJobJson = <String, Object?>{
  'job_id': 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
  'title': 'Mock: ajudante para descarregar caminhão',
  'description':
      'Mock job for staging QA. Need one person to help unload '
      'boxes from a small truck for about two hours near Centro. This is test '
      'data and should not be treated as a real opportunity.',
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
};

const feedJobsJson = <Map<String, Object?>>[
  <String, Object?>{
    'job_id': 'dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
    'title': 'Mock: ajudante para descarregar caminhão',
    'created_at': '2026-06-06T00:36:46.623Z',
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
    },
  },
];

const jobEnvelopeJson = <String, Object?>{
  'data': detailedJobJson,
  'request_id': '7a037a1d-3164-42f0-b4bf-18f3f47d3c1d',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/jobs/dfa0eb67-7b9b-4df5-9112-b92e7a8a7502',
};

const feedEnvelopeJson = <String, Object?>{
  'data': feedJobsJson,
  'request_id': '5b591550-c650-4e27-a2ed-d6f02e1c0da2',
  'timestamp': '2026-06-06T00:37:46.623Z',
  'endpoint': '/feed/jobs',
  'pagination': <String, Object?>{
    'has_more': true,
    'next_cursor': 'next-feed-cursor',
  },
};
