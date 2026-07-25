import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:locale/locale.dart';
import 'package:release/src/app_version.dart';
import 'package:release/src/changelog.dart';
import 'package:release/src/dtos/store_release_notes_dto.dart';
import 'package:release/src/environment_variables.dart';
import 'package:release/src/store_release_notes_prompt.dart';

final class AIReleaseNotesGenerator {
  AIReleaseNotesGenerator({required this.httpClient, required this.environmentVariables});

  static const int maxCharacters = 499;

  final http.Client httpClient;
  final EnvironmentVariables environmentVariables;

  Future<StoreReleaseNotesDto> generate() async {
    final currentVersion = AppVersion.current();
    final currentVersionChangelog = Changelog.currentVersion();
    final locales = AppLocaleUtils.supportedLocalesRaw;

    var releaseNotes = await _requestReleaseNotes(
      messages: [
        {
          'role': 'system',
          'content': StoreReleaseNotesPrompt.generation(locales: locales, maxCharacters: maxCharacters),
        },
        {'role': 'user', 'content': 'Version ${currentVersion.name}\n\n$currentVersionChangelog'},
      ],
      locales: locales,
    );

    releaseNotes = await _requestReleaseNotes(
      messages: [
        {'role': 'system', 'content': StoreReleaseNotesPrompt.editing(locales: locales, maxCharacters: maxCharacters)},
        {
          'role': 'user',
          'content':
              'Source changelog:\n$currentVersionChangelog\n\n'
              'Draft release notes:\n${jsonEncode(releaseNotes.toJson())}',
        },
      ],
      locales: locales,
    );

    while (_hasReleaseNoteExceedingMaxCharacters(releaseNotes)) {
      releaseNotes = await _requestReleaseNotes(
        messages: [
          {
            'role': 'system',
            'content': StoreReleaseNotesPrompt.shortening(locales: locales, maxCharacters: maxCharacters),
          },
          {'role': 'user', 'content': jsonEncode(releaseNotes.toJson())},
        ],
        locales: locales,
      );
    }

    return releaseNotes;
  }

  Future<StoreReleaseNotesDto> _requestReleaseNotes({
    required List<Map<String, String>> messages,
    required List<String> locales,
  }) async {
    final response = await _requestAIGateway(messages: messages, locales: locales);

    return _parseAIGatewayResponse(response: response, locales: locales);
  }

  Future<Map<String, Object?>> _requestAIGateway({
    required List<Map<String, String>> messages,
    required List<String> locales,
  }) async {
    final accountId = environmentVariables.getValueOrThrow('CLOUDFLARE_ACCOUNT_ID');
    final gatewayId = environmentVariables.getValueOrThrow('CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_ID');
    final apiToken = environmentVariables.getValueOrThrow('CLOUDFLARE_APP_RELEASE_NOTES_AI_GATEWAY_API_TOKEN');

    final response = await httpClient.post(
      Uri(
        scheme: 'https',
        host: 'api.cloudflare.com',
        pathSegments: ['client', 'v4', 'accounts', accountId, 'ai', 'v1', 'chat', 'completions'],
      ),

      headers: {
        'Authorization': 'Bearer $apiToken',
        'Content-Type': 'application/json',
        'cf-aig-gateway-id': gatewayId,
        'cf-aig-request-timeout': '3600000',
      },

      body: jsonEncode({
        'model': environmentVariables.getValueOrThrow('APP_RELEASE_NOTES_AI_MODEL'),
        'messages': messages,
        'response_format': _responseFormat(locales: locales),
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw StateError('AI Gateway returned HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, Object?>) {
      throw const FormatException('AI Gateway response must be a JSON map.');
    }

    return decoded;
  }

  StoreReleaseNotesDto _parseAIGatewayResponse({
    required Map<String, Object?> response,
    required List<String> locales,
  }) {
    final content = _messageContent(response);
    if (content == null) throw StateError('AI Gateway response did not contain message content.');

    final decoded = jsonDecode(content);
    if (decoded is! Map<String, Object?>) throw const FormatException('Release notes must be a JSON map.');

    final releaseNotes = StoreReleaseNotesDto.fromJson(decoded);

    final expectedLocales = [...locales]..sort();
    final actualLocales = releaseNotes.localizations.map((localization) => localization.locale).toList()..sort();

    if (!_sameLocales(expectedLocales, actualLocales)) {
      throw StateError('Expected locales $expectedLocales, got $actualLocales');
    }

    return releaseNotes;
  }

  String? _messageContent(Map<String, Object?> response) {
    final choices = response['choices'];
    if (choices is! List<Object?> || choices.isEmpty) return null;

    final first = choices.first;
    if (first is! Map<String, Object?>) return null;

    final message = first['message'];
    if (message is! Map<String, Object?>) return null;

    final content = message['content'];
    return content is String ? content : null;
  }

  Map<String, Object?> _responseFormat({required List<String> locales}) {
    return {
      'type': 'json_schema',
      'json_schema': {
        'type': 'object',
        'properties': {
          'localizations': {
            'type': 'array',
            'items': {
              'type': 'object',
              'properties': {
                'locale': {'type': 'string', 'enum': locales},
                'releaseNoteBullets': {
                  'type': 'array',
                  'items': {'type': 'string', 'minLength': 1, 'maxLength': maxCharacters},
                  'minItems': 1,
                  'maxItems': 5,
                },
              },
              'required': ['locale', 'releaseNoteBullets'],
              'additionalProperties': false,
            },
            'minItems': locales.length,
            'maxItems': locales.length,
          },
        },
        'required': ['localizations'],
        'additionalProperties': false,
      },
    };
  }

  bool _hasReleaseNoteExceedingMaxCharacters(StoreReleaseNotesDto releaseNotes) {
    return releaseNotes.localizations.any((localization) => localization.formattedReleaseNote.length > maxCharacters);
  }

  bool _sameLocales(List<String> first, List<String> second) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }

    return true;
  }
}
