import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:flutter/foundation.dart';

const Object _feedViewStateUnset = Object();

@immutable
class FeedViewState {
  const FeedViewState({
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

  FeedViewState copyWith({
    List<FeedJobDto>? jobs,
    bool? hasMore,
    Object? nextCursor = _feedViewStateUnset,
    bool? isFetchingNextPage,
    Object? paginationError = _feedViewStateUnset,
  }) {
    return FeedViewState(
      jobs: jobs ?? this.jobs,
      hasMore: hasMore ?? this.hasMore,
      nextCursor: nextCursor == _feedViewStateUnset ? this.nextCursor : nextCursor as String?,
      isFetchingNextPage: isFetchingNextPage ?? this.isFetchingNextPage,
      paginationError: paginationError == _feedViewStateUnset ? this.paginationError : paginationError,
    );
  }
}
