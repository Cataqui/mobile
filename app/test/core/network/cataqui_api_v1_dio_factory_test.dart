import 'package:cataqui_app/core/config/app_config.dart';
import 'package:cataqui_app/core/network/cataqui_api_v1_dio_factory.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late Dio dio;
  late MockHttpClientAdapter adapter;
  late RequestOptions sentRequest;

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/request'));
  });

  setUp(() {
    dio = CataquiApiV1DioFactory.create(
      appConfig: const AppConfig(flavor: 'production'),
      languageTag: 'pt-BR',
      cookieJar: CookieJar(),
    );
    adapter = MockHttpClientAdapter();
    dio.httpClientAdapter = adapter;
    when(() => adapter.fetch(any(), any(), any())).thenAnswer((invocation) async {
      sentRequest = invocation.positionalArguments.first as RequestOptions;
      return ResponseBody.fromString(
        '{}',
        200,
        headers: <String, List<String>>{
          Headers.contentTypeHeader: <String>[Headers.jsonContentType],
        },
      );
    });
  });

  tearDown(() => dio.close(force: true));

  test('when posting without a payload, it should omit the request content type', () async {
    await dio.post<void>('/auth/microservices/geosearch');

    expect((data: sentRequest.data, contentType: sentRequest.contentType), (data: null, contentType: null));
  });

  test('when posting a JSON payload, it should infer the JSON request content type', () async {
    await dio.post<void>('/auth/notp/intents', data: <String, String>{'channel': 'WHATSAPP'});

    expect(sentRequest.contentType, Headers.jsonContentType);
  });
}
