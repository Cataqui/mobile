import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/views/feed/feed_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FeedData', () {
    group('isEmpty', () {
      test('when jobs is empty, isEmpty should be true', () {
        const data = FeedData(jobs: [], hasMore: false);

        expect(data.isEmpty, isTrue);
      });

      test('when jobs is non-empty, isEmpty should be false', () {
        final data = FeedData(jobs: [FeedJobDto.fixture()], hasMore: false);

        expect(data.isEmpty, isFalse);
      });
    });

    group('isPaginationEmpty', () {
      test('when jobs is empty, isPaginationEmpty should be false', () {
        const data = FeedData(jobs: [], hasMore: false);

        expect(data.isPaginationEmpty, isFalse);
      });

      test('when jobs is non-empty and hasMore is true, isPaginationEmpty should be false', () {
        final data = FeedData(jobs: [FeedJobDto.fixture()], hasMore: true);

        expect(data.isPaginationEmpty, isFalse);
      });

      test('when jobs is non-empty and hasMore is false, isPaginationEmpty should be true', () {
        final data = FeedData(jobs: [FeedJobDto.fixture()], hasMore: false);

        expect(data.isPaginationEmpty, isTrue);
      });
    });

    group('copyWith', () {
      const originalNextCursor = 'cursor-abc';
      final originalError = StateError('test error');

      FeedData base() =>
          FeedData(jobs: [dummyJob()], hasMore: true, nextCursor: originalNextCursor, paginationError: originalError);

      test('when no arguments are passed, copyWith should preserve the jobs', () {
        final original = base();

        final copy = original.copyWith();

        expect(copy.jobs, same(original.jobs));
      });

      test('when no arguments are passed, copyWith should preserve hasMore', () {
        final copy = base().copyWith();

        expect(copy.hasMore, isTrue);
      });

      test('when no arguments are passed, copyWith should preserve the next cursor', () {
        final copy = base().copyWith();

        expect(copy.nextCursor, originalNextCursor);
      });

      test('when no arguments are passed, copyWith should preserve the pagination error', () {
        final copy = base().copyWith();

        expect(copy.paginationError, same(originalError));
      });

      test('when jobs is overridden, copyWith should use the new jobs', () {
        final copy = base().copyWith(jobs: []);

        expect(copy.jobs, isEmpty);
      });

      test('when hasMore is overridden, copyWith should use the new value', () {
        final copy = base().copyWith(hasMore: false);

        expect(copy.hasMore, isFalse);
      });

      test('when nextCursor is explicitly set to null, copyWith should set it to null', () {
        final copy = base().copyWith(nextCursor: null);

        expect(copy.nextCursor, isNull);
      });

      test('when paginationError is explicitly set to null, copyWith should set it to null', () {
        final copy = base().copyWith(paginationError: null);

        expect(copy.paginationError, isNull);
      });
    });
  });
}

FeedJobDto dummyJob() => FeedJobDto.fixture().copyWith(jobId: 'dummy_job');
