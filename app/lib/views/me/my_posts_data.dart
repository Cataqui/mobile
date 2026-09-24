import 'package:cataqui_app/core/dtos/user_job.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'my_posts_data.freezed.dart';

@freezed
abstract class MyPostsData with _$MyPostsData {
  const factory MyPostsData({
    required String userId,
    required List<UserJob> jobs,
    required bool hasMore,
    String? nextCursor,
    @Default(false) bool isLoadingMore,
    Object? paginationError,
  }) = _MyPostsData;
}
