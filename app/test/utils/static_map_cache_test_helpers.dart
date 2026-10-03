import 'package:cached_network_image/cached_network_image.dart';
import 'package:file/local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../mocks.dart';

abstract final class StaticMapCacheTestHelpers {
  static Future<void> loadImages(WidgetTester tester) async {
    final images = tester.widgetList<CachedNetworkImage>(find.byType(CachedNetworkImage, skipOffstage: false)).toList();
    if (images.isEmpty) return;
    await tester.runAsync(() async {
      await Future.wait([
        for (final image in images)
          precacheImage(
            ResizeImage.resizeIfNeeded(
              image.memCacheWidth,
              image.memCacheHeight,
              CachedNetworkImageProvider(
                image.imageUrl,
                cacheKey: image.cacheKey,
                cacheManager: image.cacheManager,
                headers: image.httpHeaders,
              ),
            ),
            tester.element(find.byWidget(image, skipOffstage: false)),
          ),
      ]);
    });
    await tester.pump();
  }

  static MockStaticMapCacheManager create() {
    final manager = MockStaticMapCacheManager();
    final square = MockStaticMapFile();
    final portrait = MockStaticMapFile();
    when(
      square.readAsBytes,
    ).thenAnswer((_) async => const LocalFileSystem().file('test/fixtures/static_map.jpg').readAsBytesSync());
    when(
      portrait.readAsBytes,
    ).thenAnswer((_) async => const LocalFileSystem().file('test/fixtures/static_map_portrait.jpg').readAsBytesSync());
    when(
      () => manager.getSingleFile(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer(
      (invocation) async =>
          Uri.parse(invocation.positionalArguments.first as String).queryParameters['size'] == '480x1280'
          ? portrait
          : square,
    );
    when(
      () => manager.getFileStream(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
        withProgress: any(named: 'withProgress'),
      ),
    ).thenAnswer(
      (invocation) => Stream<FileResponse>.value(
        FileInfo(
          Uri.parse(invocation.positionalArguments.first as String).queryParameters['size'] == '480x1280'
              ? portrait
              : square,
          FileSource.Cache,
          DateTime.utc(2100),
          invocation.positionalArguments.first as String,
        ),
      ),
    );
    return manager;
  }
}
