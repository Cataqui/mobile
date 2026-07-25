import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:release/src/ai_release_notes_generator.dart';
import 'package:release/src/dtos/localized_store_release_note_dto.dart';
import 'package:release/src/dtos/store_release_notes_dto.dart';
import 'package:release/src/environment_variables.dart';
import 'package:test/test.dart';

void main() {
  test('when requesting release notes, it should require structured output for every app locale', () async {
    Object? responseFormat;
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        responseFormat = body['response_format'];

        return http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[{\"locale\":\"pt-BR\",\"releaseNoteBullets\":[\"Novidades locais.\"]}]}"
      }
    }
  ]
}
''', 200);
      }),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    await generator.generate();

    expect(responseFormat, {
      'type': 'json_schema',
      'json_schema': {
        'type': 'object',
        'properties': {
          'localizations': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'locale': {
                  'type': 'string',
                  'enum': ['pt-BR'],
                },
                'releaseNoteBullets': {
                  'type': 'array',
                  'items': {'type': 'string', 'minLength': 1, 'maxLength': AIReleaseNotesGenerator.maxCharacters},
                  'minItems': 1,
                  'maxItems': 5,
                },
              },
              'required': ['locale', 'releaseNoteBullets'],
              'additionalProperties': false,
            },
            'minItems': 1,
            'maxItems': 1,
          },
        },
        'required': ['localizations'],
        'additionalProperties': false,
      },
    });
  });

  test('when requesting release notes, it should use the configured REST gateway and Workers AI model', () async {
    ({Uri url, String? authorization, String? gatewayId, Object? model})? requestConfiguration;
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        requestConfiguration = (
          url: request.url,
          authorization: request.headers['authorization'],
          gatewayId: request.headers['cf-aig-gateway-id'],
          model: body['model'],
        );

        return http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[{\"locale\":\"pt-BR\",\"releaseNoteBullets\":[\"Novidades locais.\"]}]}"
      }
    }
  ]
}
''', 200);
      }),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': '@cf/zai-org/glm-5.2',
        },
      ),
    );

    await generator.generate();

    expect(requestConfiguration, (
      url: Uri.parse('https://api.cloudflare.com/client/v4/accounts/account/ai/v1/chat/completions'),
      authorization: 'Bearer token',
      gatewayId: 'gateway',
      model: '@cf/zai-org/glm-5.2',
    ));
  });

  test('when editing generated release notes, it should provide the source changelog and draft', () async {
    var requestCount = 0;
    String? editorInput;
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient((request) async {
        requestCount++;
        if (requestCount == 2) {
          final body = jsonDecode(request.body) as Map<String, Object?>;
          final messages = body['messages']! as List<Object?>;
          final userMessage = messages.last! as Map<String, Object?>;
          editorInput = userMessage['content']! as String;
        }

        return http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[{\"locale\":\"pt-BR\",\"releaseNoteBullets\":[\"Novidades locais.\"]}]}"
      }
    }
  ]
}
''', 200);
      }),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    await generator.generate();

    expect(editorInput, allOf(contains('Source changelog:'), contains('Draft release notes:')));
  });

  test('when requesting release notes, it should allow Cloudflare AI Gateway to reason for sixty minutes', () async {
    String? requestTimeout;
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient((request) async {
        requestTimeout = request.headers['cf-aig-request-timeout'];

        return http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[{\"locale\":\"pt-BR\",\"releaseNoteBullets\":[\"Novidades locais.\"]}]}"
      }
    }
  ]
}
''', 200);
      }),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    await generator.generate();

    expect(requestTimeout, '3600000');
  });

  test('when Cloudflare returns localized JSON, it should extract every locale', () async {
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient(
        (_) async => http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[{\"locale\":\"pt-BR\",\"releaseNoteBullets\":[\"Novidades locais.\"]}]}"
      }
    }
  ]
}
''', 200),
      ),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    final notes = await generator.generate();

    expect(
      notes,
      const StoreReleaseNotesDto(
        localizations: [
          LocalizedStoreReleaseNoteDto(locale: 'pt-BR', releaseNoteBullets: ['Novidades locais.']),
        ],
      ),
    );
  });

  test('when Cloudflare returns multiple bullet sentences, it should format each one on its own store line', () async {
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient(
        (_) async => http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[{\"locale\":\"pt-BR\",\"releaseNoteBullets\":[\"Primeira novidade.\",\"Segunda novidade.\"]}]}"
      }
    }
  ]
}
''', 200),
      ),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    final notes = await generator.generate();

    expect(notes.localizations.single.formattedReleaseNote, '• Primeira novidade.\n• Segunda novidade.');
  });

  test(
    'when generated release notes remain too long, it should keep requesting shorter notes until they fit',
    () async {
      var requestCount = 0;
      final generator = AIReleaseNotesGenerator(
        httpClient: MockClient((_) async {
          requestCount++;
          final releaseNote = requestCount < 3 ? List.filled(500, 'a').join() : 'Novidades mais curtas.';

          return http.Response(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content': jsonEncode({
                      'localizations': [
                        {
                          'locale': 'pt-BR',
                          'releaseNoteBullets': [releaseNote],
                        },
                      ],
                    }),
                  },
                },
              ],
            }),
            200,
          );
        }),
        environmentVariables: EnvironmentVariables(
          values: {
            'CLOUDFLARE_ACCOUNT_ID': 'account',
            'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
            'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
            'APP_RELEASE_NOTES_AI_MODEL': 'model',
          },
        ),
      );

      final releaseNotes = await generator.generate();

      expect(
        (requestCount: requestCount, releaseNotes: releaseNotes),
        (
          requestCount: 3,
          releaseNotes: const StoreReleaseNotesDto(
            localizations: [
              LocalizedStoreReleaseNoteDto(locale: 'pt-BR', releaseNoteBullets: ['Novidades mais curtas.']),
            ],
          ),
        ),
      );
    },
  );

  test('when generated release notes are too long, it should use the shortening prompt for the next request', () async {
    final systemPrompts = <String>[];
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, Object?>;
        final messages = body['messages']! as List<Object?>;
        final systemMessage = messages.first! as Map<String, Object?>;
        systemPrompts.add(systemMessage['content']! as String);

        final releaseNote = systemPrompts.length <= 2 ? List.filled(500, 'a').join() : 'Novidades mais curtas.';

        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'localizations': [
                      {
                        'locale': 'pt-BR',
                        'releaseNoteBullets': [releaseNote],
                      },
                    ],
                  }),
                },
              },
            ],
          }),
          200,
        );
      }),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    await generator.generate();

    expect(systemPrompts[2], startsWith('Shorten'));
  });

  test('when Cloudflare omits an app locale, it should reject the response', () {
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient(
        (_) async => http.Response(r'''
{
  "choices": [
    {
      "message": {
        "content": "{\"localizations\":[]}"
      }
    }
  ]
}
''', 200),
      ),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    expect(generator.generate(), throwsStateError);
  });

  test('when Cloudflare rejects the request, it should expose the response failure', () {
    final generator = AIReleaseNotesGenerator(
      httpClient: MockClient((_) async => http.Response('Gateway unavailable', 503)),
      environmentVariables: EnvironmentVariables(
        values: {
          'CLOUDFLARE_ACCOUNT_ID': 'account',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN': 'token',
          'CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID': 'gateway',
          'APP_RELEASE_NOTES_AI_MODEL': 'model',
        },
      ),
    );

    expect(generator.generate(), throwsStateError);
  });
}
