import 'dart:io';
import 'dart:ui' as ui;

import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:file/local.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';

void main() {
  late Directory directory;
  late MockStaticMapFileSystem fileSystem;
  late MockStaticMapFileService fileService;
  late MockStaticMapFileServiceResponse response;
  late CacheManager manager;
  const request = StaticMapRequest(imageUrl: 'https://maps.cataqui.com/static/fixture', size: .pixels960x960);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('cataqui_static_map_cache_test');
    fileSystem = MockStaticMapFileSystem();
    fileService = MockStaticMapFileService();
    when(() => fileService.concurrentFetches).thenReturn(10);
    response = MockStaticMapFileServiceResponse();
    final bytes = const LocalFileSystem().file('test/fixtures/static_map.jpg').readAsBytesSync();
    when(() => fileSystem.createFile(any())).thenAnswer(
      (invocation) async => const LocalFileSystem().file('${directory.path}/${invocation.positionalArguments.first}'),
    );
    when(() => response.statusCode).thenReturn(200);
    when(() => response.validTill).thenReturn(DateTime.now().add(const Duration(days: 1)));
    when(() => response.eTag).thenReturn('image-etag');
    when(() => response.fileExtension).thenReturn('.jpg');
    when(() => response.contentLength).thenReturn(bytes.length);
    when(() => response.content).thenAnswer((_) => Stream<List<int>>.value(bytes));
    when(() => fileService.get(any(), headers: any(named: 'headers'))).thenAnswer((_) async => response);
    manager = _StaticMapCacheTestHelpers.manager(
      directory: directory,
      fileSystem: fileSystem,
      fileService: fileService,
    );
  });
  tearDown(() async {
    await manager.dispose();
    await directory.delete(recursive: true);
  });
  test('when an image is downloaded, it should download the ready URL without authorization', () async {
    await manager.getSingleFile(request.url, key: request.cacheKey);
    verify(() => fileService.get(request.url, headers: <String, String>{})).called(1);
  });
  test('when the cache reopens, it should reuse the public image without another download', () async {
    await manager.getSingleFile(request.url, key: request.cacheKey);
    await manager.dispose();
    manager = _StaticMapCacheTestHelpers.manager(
      directory: directory,
      fileSystem: fileSystem,
      fileService: fileService,
    );
    await manager.getSingleFile(request.url, key: request.cacheKey);
    verify(() => fileService.get(any(), headers: any(named: 'headers'))).called(1);
  });
  test('when offline with a fresh cached image, it should deliver the saved JPEG', () async {
    final saved = await manager.getSingleFile(request.url, key: request.cacheKey);
    when(() => fileService.get(any(), headers: any(named: 'headers'))).thenThrow(const SocketException('offline'));
    final cached = await manager.getSingleFile(request.url, key: request.cacheKey);
    expect(await cached.readAsBytes(), await saved.readAsBytes());
  });
  test('when WebP is downloaded and the cache reopens offline, it should decode the saved image', () async {
    final bytes = const LocalFileSystem().file('test/fixtures/static_map.webp').readAsBytesSync();
    when(() => response.validTill).thenReturn(DateTime.now().add(const Duration(days: 365)));
    when(() => response.fileExtension).thenReturn('.webp');
    when(() => response.contentLength).thenReturn(bytes.length);
    when(() => response.content).thenAnswer((_) => Stream<List<int>>.value(bytes));
    await manager.getSingleFile(request.url, key: request.cacheKey);
    await manager.dispose();
    manager = _StaticMapCacheTestHelpers.manager(
      directory: directory,
      fileSystem: fileSystem,
      fileService: fileService,
    );
    when(() => fileService.get(any(), headers: any(named: 'headers'))).thenThrow(const SocketException('offline'));
    final cached = await manager.getSingleFile(request.url, key: request.cacheKey);
    final codec = await ui.instantiateImageCodec(await cached.readAsBytes());
    final frame = await codec.getNextFrame();
    try {
      expect((cached.path.endsWith('.webp'), frame.image.width, frame.image.height), (true, 64, 64));
    } finally {
      frame.image.dispose();
      codec.dispose();
    }
  });
  test('when a public image expires, it should revalidate the stored ETag without authorization', () async {
    when(() => response.validTill).thenReturn(DateTime.now().subtract(const Duration(seconds: 1)));
    await manager.getSingleFile(request.url, key: request.cacheKey);
    when(() => response.validTill).thenReturn(DateTime.now().add(const Duration(days: 1)));
    await manager.getFileStream(request.url, key: request.cacheKey).toList();
    verify(
      () => fileService.get(request.url, headers: <String, String>{HttpHeaders.ifNoneMatchHeader: 'image-etag'}),
    ).called(1);
  });
  test('when simultaneous callers request an image, it should share its download', () async {
    await Future.wait([
      for (var index = 0; index < 3; index++) manager.getSingleFile(request.url, key: request.cacheKey),
    ]);
    verify(() => fileService.get(any(), headers: any(named: 'headers'))).called(1);
  });
  test('when a public image is missing, it should not retain the error response as an image', () async {
    when(() => response.statusCode).thenReturn(404);
    await manager.getSingleFile(request.url, key: request.cacheKey).then((_) {}, onError: (Object error) {});
    expect(await manager.getFileFromCache(request.cacheKey), isNull);
  });
}

abstract final class _StaticMapCacheTestHelpers {
  static CacheManager manager({
    required Directory directory,
    required MockStaticMapFileSystem fileSystem,
    required MockStaticMapFileService fileService,
  }) => CacheManager(
    Config(
      'cataqui_static_map_test',
      repo: JsonCacheInfoRepository(path: '${directory.path}/cache.json'),
      fileSystem: fileSystem,
      fileService: fileService,
    ),
  );
}
