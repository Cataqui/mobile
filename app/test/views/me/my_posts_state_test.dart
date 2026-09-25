import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/api_pagination_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../mocks.dart';
import 'fake_app_auth_state.dart';

void main() {
  late MockUserRepository userRepository;
  late FakeAppAuthState authState;
  late ProviderContainer container;

  setUp(() {
    userRepository = MockUserRepository();
    authState = FakeAppAuthState(null);
    when(
      userRepository.getMyPostedJobs,
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: [UserJobSummaryDto.fixture()]));
    container = ProviderContainer(
      overrides: [
        userRepositoryProvider.overrideWithValue(userRepository),
        appAuthStateProvider.overrideWith(() => authState),
      ],
    )..listen(myPostsStateProvider, (_, _) {});
  });

  tearDown(() => container.dispose());

  test('when signed out, it should keep the jobs empty without requesting the API', () async {
    expect(await container.read(myPostsStateProvider.future), isNull);
    verifyNever(userRepository.getMyPostedJobs);
  });

  test('when a user signs in then another user signs in, it should load each user’s jobs', () async {
    await container.read(myPostsStateProvider.future);

    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'first-user');
    await container.pump();
    expect((await container.read(myPostsStateProvider.future))?.jobs, [UserJobSummaryDto.fixture()]);

    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-user');
    await container.pump();
    expect((await container.read(myPostsStateProvider.future))?.jobs, [UserJobSummaryDto.fixture()]);
    verify(userRepository.getMyPostedJobs).called(2);
  });

  test('when a session renews for the same user, it should keep the loaded jobs without refetching', () async {
    final session = AuthSessionDto.fixture().copyWith(userId: 'same-user');
    authState.currentSession = session;
    await container.pump();
    await container.read(myPostsStateProvider.future);

    authState.currentSession = session.copyWith(accessToken: 'renewed-token');
    await container.pump();

    expect(container.read(myPostsStateProvider).value?.jobs, [UserJobSummaryDto.fixture()]);
    verify(userRepository.getMyPostedJobs).called(1);
  });

  test('when the user changes during pagination, it should keep only the new user’s jobs', () async {
    final oldPage = Completer<ApiEnvelopeDto<List<UserJobSummaryDto>>>();
    var initialRequests = 0;
    when(userRepository.getMyPostedJobs).thenAnswer((_) async {
      initialRequests += 1;
      return ApiEnvelopeDto.fixture(
        data: [UserJobSummaryDto.fixture().copyWith(jobId: 'user-$initialRequests')],
      ).copyWith(
        pagination: ApiPaginationDto(
          hasMore: initialRequests == 1,
          nextCursor: initialRequests == 1 ? 'old-page' : null,
        ),
      );
    });
    when(() => userRepository.getMyPostedJobs(cursor: 'old-page')).thenAnswer((_) => oldPage.future);
    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'first-user');
    await container.pump();
    await container.read(myPostsStateProvider.future);

    final pendingPage = container.read(myPostsStateProvider.notifier).loadNextPage();
    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-user');
    await container.pump();
    await container.read(myPostsStateProvider.future);
    expect(initialRequests, 2);

    oldPage.complete(ApiEnvelopeDto.fixture(data: [UserJobSummaryDto.fixture().copyWith(jobId: 'old-page-job')]));
    await pendingPage;

    expect(container.read(myPostsStateProvider).value?.jobs.map((job) => job.jobId), ['user-2']);
  });

  test('when the user changes during the first request, it should discard the old user’s response', () async {
    final firstResponse = Completer<ApiEnvelopeDto<List<UserJobSummaryDto>>>();
    var requestCount = 0;
    when(userRepository.getMyPostedJobs).thenAnswer((_) {
      requestCount += 1;
      if (requestCount == 1) return firstResponse.future;
      return Future.value(
        ApiEnvelopeDto.fixture(data: [UserJobSummaryDto.fixture().copyWith(jobId: 'second-user-job')]),
      );
    });
    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'first-user');
    await container.pump();

    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-user');
    await container.pump();
    await container.read(myPostsStateProvider.future);

    firstResponse.complete(
      ApiEnvelopeDto.fixture(data: [UserJobSummaryDto.fixture().copyWith(jobId: 'first-user-job')]),
    );
    await container.pump();

    expect(container.read(myPostsStateProvider).value?.jobs.map((job) => job.jobId), ['second-user-job']);
  });

  test('when reaching the next page, it should append jobs and stop at the last page', () async {
    final firstJob = UserJobSummaryDto.fixture().copyWith(jobId: 'first-job');
    final secondJob = UserJobSummaryDto.fixture().copyWith(jobId: 'second-job');
    when(userRepository.getMyPostedJobs).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [firstJob],
      ).copyWith(pagination: const ApiPaginationDto(hasMore: true, nextCursor: 'page-two')),
    );
    when(() => userRepository.getMyPostedJobs(cursor: 'page-two')).thenAnswer(
      (_) async =>
          ApiEnvelopeDto.fixture(data: [secondJob]).copyWith(pagination: const ApiPaginationDto(hasMore: false)),
    );
    authState.currentSession = AuthSessionDto.fixture();
    await container.pump();
    await container.read(myPostsStateProvider.future);

    await container.read(myPostsStateProvider.notifier).loadNextPage();
    await container.read(myPostsStateProvider.notifier).loadNextPage();

    expect(container.read(myPostsStateProvider).value?.jobs, [firstJob, secondJob]);
    expect(container.read(myPostsStateProvider).value?.hasMore, isFalse);
    verify(() => userRepository.getMyPostedJobs(cursor: 'page-two')).called(1);
  });

  test('when a page is already loading, it should not make another page request', () async {
    final nextPage = Completer<ApiEnvelopeDto<List<UserJobSummaryDto>>>();
    when(userRepository.getMyPostedJobs).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [UserJobSummaryDto.fixture()],
      ).copyWith(pagination: const ApiPaginationDto(hasMore: true, nextCursor: 'page-two')),
    );
    when(() => userRepository.getMyPostedJobs(cursor: 'page-two')).thenAnswer((_) => nextPage.future);
    authState.currentSession = AuthSessionDto.fixture();
    await container.pump();
    await container.read(myPostsStateProvider.future);

    final firstLoad = container.read(myPostsStateProvider.notifier).loadNextPage();
    await container.read(myPostsStateProvider.notifier).loadNextPage();

    expect(container.read(myPostsStateProvider).value?.isLoadingMore, isTrue);
    verify(() => userRepository.getMyPostedJobs(cursor: 'page-two')).called(1);

    nextPage.complete(
      ApiEnvelopeDto.fixture(data: <UserJobSummaryDto>[]).copyWith(pagination: const ApiPaginationDto(hasMore: false)),
    );
    await firstLoad;
  });

  test('when a later page fails, it should keep the jobs and allow a retry', () async {
    var pageRequests = 0;
    when(userRepository.getMyPostedJobs).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [UserJobSummaryDto.fixture()],
      ).copyWith(pagination: const ApiPaginationDto(hasMore: true, nextCursor: 'page-two')),
    );
    when(() => userRepository.getMyPostedJobs(cursor: 'page-two')).thenAnswer((_) async {
      pageRequests += 1;
      if (pageRequests == 1) throw StateError('offline');
      return ApiEnvelopeDto.fixture(
        data: [UserJobSummaryDto.fixture().copyWith(jobId: 'second-job')],
      ).copyWith(pagination: const ApiPaginationDto(hasMore: false));
    });
    authState.currentSession = AuthSessionDto.fixture();
    await container.pump();
    await container.read(myPostsStateProvider.future);

    await container.read(myPostsStateProvider.notifier).loadNextPage();
    expect(container.read(myPostsStateProvider).value?.jobs, [UserJobSummaryDto.fixture()]);
    expect(container.read(myPostsStateProvider).value?.paginationError, isA<StateError>());

    await container.read(myPostsStateProvider.notifier).loadNextPage();
    expect(container.read(myPostsStateProvider).value?.jobs, [
      UserJobSummaryDto.fixture(),
      UserJobSummaryDto.fixture().copyWith(jobId: 'second-job'),
    ]);
    expect(container.read(myPostsStateProvider).value?.paginationError, isNull);
  });
}
