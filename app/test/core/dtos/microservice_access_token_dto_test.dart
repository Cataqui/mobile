import 'package:cataqui_app/core/dtos/microservice_access_token_dto.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MicroserviceAccessTokenDto', () {
    test('when the token type is not bearer, it should reject the response', () {
      expect(
        () => MicroserviceAccessTokenDto.fromJson(const <String, Object?>{
          'accessToken': 'header.payload.signature',
          'expiresAt': '2026-08-22T15:10:00.000Z',
          'tokenType': 'Basic',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('when the expiration timestamp is invalid, it should reject the response', () {
      expect(
        () => MicroserviceAccessTokenDto.fromJson(const <String, Object?>{
          'accessToken': 'header.payload.signature',
          'expiresAt': 'later',
          'tokenType': 'Bearer',
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
