import 'dart:async';

import 'package:cataqui_app/core/static_map/static_map_request.dart';
import 'package:cataqui_app/widgets/job_location_image/job_location_image_prefetcher.dart';
import 'package:file/file.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import '../../utils/static_map_cache_test_helpers.dart';

void main() {
  late MockStaticMapCacheManager cacheManager;
  late MockStaticMapFile cachedFile;
  late JobLocationImagePrefetcher prefetcher;
  late List<String> started;
  late Map<String, Completer<File>> downloads;
  late List<String> preparing;
  late Map<String, Completer<void>> preparations;
  setUp(() {
    cacheManager = StaticMapCacheTestHelpers.create();
    cachedFile = MockStaticMapFile();
    started = [];
    downloads = {};
    preparing = [];
    preparations = {};
    when(
      () => cacheManager.getSingleFile(
        any(),
        key: any(named: 'key'),
        headers: any(named: 'headers'),
      ),
    ).thenAnswer((invocation) {
      final key = invocation.namedArguments[#key]! as String;
      started.add(key);
      return (downloads[key] = Completer<File>()).future;
    });
    prefetcher = JobLocationImagePrefetcher(
      cacheManager: cacheManager,
      prepareImage: (request) {
        preparing.add(request.cacheKey);
        return (preparations[request.cacheKey] = Completer<void>()).future;
      },
    );
  });
  tearDown(() => prefetcher.dispose());

  test('when the lookahead changes, it should cap downloads and replace obsolete queued work', () async {
    final requests = List.generate(6, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher.update(requests: requests.take(4).toList());
    final initiallyStarted = [...started];
    prefetcher.update(requests: [requests[1], requests[4], requests[5]]);
    downloads[requests[0].cacheKey]!.complete(cachedFile);
    await Future<void>.delayed(Duration.zero);
    final afterFirstCompletes = [...started];
    downloads[requests[1].cacheKey]!.complete(cachedFile);
    await Future<void>.delayed(Duration.zero);
    expect(
      [initiallyStarted, afterFirstCompletes, started],
      [
        requests.take(2).map((request) => request.cacheKey).toList(),
        [requests[0].cacheKey, requests[1].cacheKey, requests[4].cacheKey],
        [requests[0].cacheKey, requests[1].cacheKey, requests[4].cacheKey, requests[5].cacheKey],
      ],
    );
  });

  test('when builds repeat or map keys repeat, it should attempt each map once per lookahead window', () async {
    final request = _JobLocationImagePrefetcherTestHelpers.request(0);
    prefetcher
      ..update(requests: [request, request])
      ..update(requests: [request]);
    final attemptsWhileDownloading = started.length;
    downloads[request.cacheKey]!.complete(cachedFile);
    await Future<void>.delayed(Duration.zero);
    prefetcher.update(requests: [request]);
    final attemptsAfterDownloading = started.length;
    prefetcher
      ..update(requests: [])
      ..update(requests: [request]);
    expect(
      [attemptsWhileDownloading, attemptsAfterDownloading, started],
      [
        1,
        1,
        [request.cacheKey, request.cacheKey],
      ],
    );
  });

  test('when a download fails, it should continue queued work without looping retries', () async {
    final requests = List.generate(3, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher.update(requests: requests);
    downloads[requests.first.cacheKey]!.completeError(Exception('offline'));
    await Future<void>.delayed(Duration.zero);
    final afterFailure = [...started];
    prefetcher.update(requests: requests);
    expect(
      [afterFailure, started],
      [requests.map((request) => request.cacheKey).toList(), requests.map((request) => request.cacheKey).toList()],
    );
  });

  test('when only downloading upcoming maps, it should leave decoding to the visible image', () async {
    final request = _JobLocationImagePrefetcherTestHelpers.request(0);
    prefetcher.update(requests: [request]);
    downloads[request.cacheKey]!.complete(cachedFile);
    await Future<void>.delayed(Duration.zero);

    expect(started, [request.cacheKey]);
    expect(preparing, isEmpty);
    verify(() => cacheManager.getSingleFile(request.url, key: request.cacheKey)).called(1);
  });

  test('when disposed, it should allow active downloads to finish without starting queued work', () async {
    final requests = List.generate(3, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher
      ..update(requests: requests)
      ..dispose();
    downloads[requests.first.cacheKey]!.complete(cachedFile);
    await Future<void>.delayed(Duration.zero);
    prefetcher.update(requests: requests);
    expect(started.length, 2);
  });

  test('when two maps are still being decoded, it should wait before preparing another map', () async {
    final requests = List.generate(3, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher.update(requests: [requests[2]], decodedRequests: requests.take(2).toList());
    final beforeDecodeCompletes = {
      'preparing': [...preparing],
      'downloading': [...started],
    };

    preparations[requests[0].cacheKey]!.complete();
    await Future<void>.delayed(Duration.zero);

    expect(
      {'beforeDecodeCompletes': beforeDecodeCompletes, 'downloadingAfterDecode': started},
      {
        'beforeDecodeCompletes': {
          'preparing': requests.take(2).map((request) => request.cacheKey).toList(),
          'downloading': <String>[],
        },
        'downloadingAfterDecode': [requests[2].cacheKey],
      },
    );
  });

  test(
    'when a map starts downloading before it needs decoding, it should finish that download before preparing it',
    () async {
      final requests = List.generate(3, _JobLocationImagePrefetcherTestHelpers.request);
      prefetcher
        ..update(requests: requests.take(2).toList())
        ..update(requests: requests, decodedRequests: [requests[0]]);
      final preparingDuringDownload = [...preparing];

      downloads[requests[0].cacheKey]!.complete(cachedFile);
      await Future<void>.delayed(Duration.zero);
      final duringDecode = {
        'preparing': [...preparing],
        'downloading': [...started],
      };

      prefetcher.update(requests: requests, decodedRequests: [requests[0], requests[0]]);
      preparations[requests[0].cacheKey]!.complete();
      await Future<void>.delayed(Duration.zero);

      expect(
        {
          'preparingDuringDownload': preparingDuringDownload,
          'duringDecode': duringDecode,
          'preparing': preparing,
          'downloading': started,
        },
        {
          'preparingDuringDownload': <String>[],
          'duringDecode': {
            'preparing': [requests[0].cacheKey],
            'downloading': requests.take(2).map((request) => request.cacheKey).toList(),
          },
          'preparing': [requests[0].cacheKey],
          'downloading': requests.map((request) => request.cacheKey).toList(),
        },
      );
    },
  );

  test(
    'when a previously downloaded map becomes the next card, it should prepare it once without downloading it again',
    () async {
      final request = _JobLocationImagePrefetcherTestHelpers.request(0);
      prefetcher.update(requests: [request]);
      downloads[request.cacheKey]!.complete(cachedFile);
      await Future<void>.delayed(Duration.zero);

      prefetcher
        ..update(requests: [request], decodedRequests: [request])
        ..update(requests: [request], decodedRequests: [request]);
      preparations[request.cacheKey]!.complete();
      await Future<void>.delayed(Duration.zero);
      prefetcher.update(requests: [request], decodedRequests: [request]);

      expect(
        {'downloading': started, 'preparing': preparing},
        {
          'downloading': [request.cacheKey],
          'preparing': [request.cacheKey],
        },
      );
    },
  );

  test('when the upcoming decoded maps change, it should discard queued maps that are no longer needed', () async {
    final requests = List.generate(5, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher
      ..update(requests: [], decodedRequests: requests.take(4).toList())
      ..update(requests: [], decodedRequests: [requests[1], requests[4]]);

    preparations[requests[0].cacheKey]!.complete();
    await Future<void>.delayed(Duration.zero);
    preparations[requests[1].cacheKey]!.complete();
    await Future<void>.delayed(Duration.zero);

    expect(preparing, [requests[0].cacheKey, requests[1].cacheKey, requests[4].cacheKey]);
  });

  test('when a landing map becomes important, it should prepare it before the farther queued downloads', () async {
    final requests = List.generate(5, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher
      ..update(requests: requests.take(4).toList())
      ..update(requests: requests.take(4).toList(), decodedRequests: [requests[4]]);

    downloads[requests[0].cacheKey]!.complete(cachedFile);
    await Future<void>.delayed(Duration.zero);

    expect(
      {'downloading': started, 'preparing': preparing},
      {
        'downloading': requests.take(2).map((request) => request.cacheKey).toList(),
        'preparing': [requests[4].cacheKey],
      },
    );
  });

  test('when a map cannot be decoded, it should prepare another map without repeatedly retrying the failure', () async {
    final requests = List.generate(3, _JobLocationImagePrefetcherTestHelpers.request);
    prefetcher.update(requests: [], decodedRequests: requests);

    preparations[requests[0].cacheKey]!.completeError(Exception('invalid image'));
    await Future<void>.delayed(Duration.zero);
    prefetcher.update(requests: [], decodedRequests: requests);

    expect(preparing, requests.map((request) => request.cacheKey));
  });

  test(
    'when the carousel closes while a map is being decoded, it should finish active work without preparing queued maps',
    () async {
      final requests = List.generate(4, _JobLocationImagePrefetcherTestHelpers.request);
      prefetcher
        ..update(requests: [requests[3]], decodedRequests: requests.take(3).toList())
        ..dispose();

      preparations[requests[0].cacheKey]!.complete();
      preparations[requests[1].cacheKey]!.complete();
      await Future<void>.delayed(Duration.zero);
      prefetcher.update(requests: requests, decodedRequests: requests);

      expect(
        {'preparing': preparing, 'downloading': started},
        {'preparing': requests.take(2).map((request) => request.cacheKey).toList(), 'downloading': <String>[]},
      );
    },
  );

  test(
    'when a queued decode upgrade is no longer wanted, it should keep the finished download without decoding it',
    () async {
      final requests = List.generate(3, _JobLocationImagePrefetcherTestHelpers.request);
      prefetcher
        ..update(requests: requests.take(2).toList())
        ..update(requests: requests, decodedRequests: [requests[0]])
        ..update(requests: requests);

      downloads[requests[0].cacheKey]!.complete(cachedFile);
      await Future<void>.delayed(Duration.zero);

      expect(
        {'downloading': started, 'preparing': preparing},
        {'downloading': requests.map((request) => request.cacheKey).toList(), 'preparing': <String>[]},
      );
    },
  );
}

abstract final class _JobLocationImagePrefetcherTestHelpers {
  static StaticMapRequest request(int index) =>
      StaticMapRequest(imageUrl: 'https://maps.cataqui.com/static/fixture-$index', size: .pixels960x2560);
}
