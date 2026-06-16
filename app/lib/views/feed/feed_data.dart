import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:flutter/foundation.dart';

const Object _feedDataUnset = Object();

@immutable
class FeedData {
  const FeedData({
    required this.jobs,
    required this.hasMore,
    this.nextCursor,
    this.isFetchingNextPage = false,
    this.paginationError,
  });

  final List<FeedJobDto> jobs;
  final bool hasMore;
  final String? nextCursor;
  final bool isFetchingNextPage;
  final Object? paginationError;

  bool get isEmpty => jobs.isEmpty;

  bool get isPaginationEmpty => jobs.isNotEmpty && !hasMore;

  FeedData copyWith({
    List<FeedJobDto>? jobs,
    bool? hasMore,
    Object? nextCursor = _feedDataUnset,
    bool? isFetchingNextPage,
    Object? paginationError = _feedDataUnset,
  }) {
    return FeedData(
      jobs: jobs ?? this.jobs,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor == _feedDataUnset ? this.nextCursor : nextCursor as String?,
      isFetchingNextPage: isFetchingNextPage ?? this.isFetchingNextPage,
      paginationError: paginationError == _feedDataUnset ? this.paginationError : paginationError,
    );
  }
}
