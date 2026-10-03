import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/auth_session_dto.dart';
import 'package:cataqui_app/core/dtos/contact_dto.dart';
import 'package:cataqui_app/core/dtos/feed_job_dto.dart';
import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_summary_dto.dart';
import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:cataqui_app/core/enums/job_status.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';
import '../fake_app_auth_state.dart';

void main() {
  late MockUserRepository userRepository;
  late MockJobRepository jobRepository;
  late MockFeedRepository feedRepository;
  late ProviderContainer container;
  late FakeAppAuthState authState;

  setUp(() {
    userRepository = MockUserRepository();
    jobRepository = MockJobRepository();
    feedRepository = MockFeedRepository();
    authState = FakeAppAuthState(AuthSessionDto.fixture().copyWith(userId: 'first-user'));
    when(
      () => userRepository.getMyPostedJobs(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: <UserJobSummaryDto>[]));
    when(
      () => feedRepository.getFeedJobs(cursor: any(named: 'cursor')),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: <FeedJobDto>[]));
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(
          jobId: 'job-123',
          description: 'Detalhes do post',
          updatedAt: DateTime.utc(2026, 10, 2, 9),
          contact: ContactDto.fixture().copyWith(method: .whatsapp, identifier: '+5511999999999'),
        ),
      ),
    );
    container = ProviderContainer(
      overrides: [
        appAuthStateProvider.overrideWith(() => authState),
        userRepositoryProvider.overrideWithValue(userRepository),
        jobRepositoryProvider.overrideWithValue(jobRepository),
        feedRepositoryProvider.overrideWithValue(feedRepository),
      ],
    )..read(appAuthStateProvider);
  });

  tearDown(() => container.dispose());

  test('loads the selected user job detail', () async {
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    final data = await container.read(myPostStateProvider('job-123').future);

    expect(data.detail.jobId, 'job-123');
    expect(data.detail.description, 'Detalhes do post');
    expect(data.contactLabel, '+55 11 99999-9999');
    verify(() => userRepository.getMyPostedJob(jobId: 'job-123')).called(1);
  });

  test('publishes the detail and formatted contact together', () async {
    final states = <AsyncValue<MyPostData>>[];
    container.listen(myPostStateProvider('job-123'), (_, next) => states.add(next), fireImmediately: true);

    await container.read(myPostStateProvider('job-123').future);

    expect(states.whereType<AsyncData<MyPostData>>(), hasLength(1));
    expect(states.whereType<AsyncData<MyPostData>>().single.value.contactLabel, '+55 11 99999-9999');
  });

  test('keeps unknown contact identifiers unchanged', () async {
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(
          contact: const ContactDto(method: ContactMethod.unknown, identifier: 'other-contact'),
        ),
      ),
    );

    container.listen(myPostStateProvider('job-123'), (_, _) {});
    final data = await container.read(myPostStateProvider('job-123').future);

    expect(data.contactLabel, 'other-contact');
  });

  test('archives the loaded post and preserves its formatted contact', () async {
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: PublicJobDto.fixture().copyWith(status: .archived, updatedAt: DateTime.utc(2026, 10, 2, 10)),
      ),
    );
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    final before = await container.read(myPostStateProvider('job-123').future);

    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: JobStatus.archived);

    final after = container.read(myPostStateProvider('job-123')).requireValue;
    expect(after.detail.status, JobStatus.archived);
    expect(after.contactLabel, before.contactLabel);
    verify(() => jobRepository.archiveJob(jobId: 'job-123')).called(1);
  });

  test('archives before detail loads and applies the status to the later detail', () async {
    final detailResponse = Completer<ApiEnvelopeDto<UserJobDto>>();
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer((_) => detailResponse.future);
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: PublicJobDto.fixture().copyWith(status: .archived, updatedAt: DateTime.utc(2026, 10, 2, 10)),
      ),
    );
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    final pendingDetail = container.read(myPostStateProvider('job-123').future);

    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: JobStatus.archived);
    expect(container.read(myPostStateProvider('job-123')).isLoading, isTrue);
    verify(() => jobRepository.archiveJob(jobId: 'job-123')).called(1);

    detailResponse.complete(
      ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(jobId: 'job-123', status: .active, updatedAt: DateTime.utc(2026, 10, 2, 9)),
      ),
    );
    final detail = await pendingDetail;
    expect(detail.detail.status, JobStatus.archived);
  });

  test('archiving a newly posted job removes it from the feed and future refreshes', () async {
    final job = PublicJobDto.fixture().copyWith(
      jobId: 'job-123',
      status: .active,
      updatedAt: DateTime.utc(2026, 10, 2, 10),
    );
    when(
      () => jobRepository.archiveJob(jobId: 'job-123'),
    ).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: job.copyWith(status: .archived)));
    await container.read(feedStateProvider.future);
    container.read(feedStateProvider.notifier).injectJob(job);
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);

    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: .archived);
    await container.pump();
    await container.read(feedStateProvider.future);

    expect(container.read(feedStateProvider).requireValue.jobs, isEmpty);
    await container.read(feedStateProvider.notifier).getFeedJobs();
    expect(container.read(feedStateProvider).requireValue.jobs, isEmpty);
  });

  test('activating an older post reloads the feed in backend chronology', () async {
    final job = PublicJobDto.fixture().copyWith(
      jobId: 'job-123',
      status: .active,
      updatedAt: DateTime.utc(2026, 10, 2, 10),
    );
    when(() => jobRepository.activateJob(jobId: 'job-123')).thenAnswer((_) async => ApiEnvelopeDto.fixture(data: job));
    await container.read(feedStateProvider.future);
    when(() => feedRepository.getFeedJobs()).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: [
          FeedJobDto.fixture().copyWith(jobId: 'newer-job'),
          FeedJobDto.fromPublicJob(job),
        ],
      ),
    );
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);

    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: .active);
    await container.pump();
    await container.read(feedStateProvider.future);

    expect(container.read(feedStateProvider).requireValue.jobs.map((job) => job.jobId), ['newer-job', 'job-123']);
  });

  test('closing detail while retrying finishes without writing disposed state', () async {
    final subscription = container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    final detailResponse = Completer<ApiEnvelopeDto<UserJobDto>>();
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer((_) => detailResponse.future);
    final retry = container.read(myPostStateProvider('job-123').notifier).retry();

    subscription.close();
    await container.pump();
    detailResponse.complete(ApiEnvelopeDto.fixture(data: UserJobDto.fixture()));

    await expectLater(retry, completes);
  });

  test('closing detail during archiving still synchronizes the feed', () async {
    final job = PublicJobDto.fixture().copyWith(
      jobId: 'job-123',
      status: .active,
      updatedAt: DateTime.utc(2026, 10, 2, 10),
    );
    await container.read(feedStateProvider.future);
    container.read(feedStateProvider.notifier).injectJob(job);
    final subscription = container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    final archiveResponse = Completer<ApiEnvelopeDto<PublicJobDto>>();
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer((_) => archiveResponse.future);
    final archive = container.read(myPostStateProvider('job-123').notifier).changeStatus(status: .archived);

    subscription.close();
    await container.pump();
    archiveResponse.complete(ApiEnvelopeDto.fixture(data: job.copyWith(status: .archived)));
    await archive;
    await container.read(feedStateProvider.future);

    expect(container.read(feedStateProvider).requireValue.jobs, isEmpty);
    await container.pump();
    expect(container.exists(myPostStateProvider('job-123')), isFalse);
  });

  test('a newer backend detail supersedes an earlier local status update', () async {
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: PublicJobDto.fixture().copyWith(status: .archived, updatedAt: DateTime.utc(2026, 10, 2, 10)),
      ),
    );
    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: .archived);
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(status: .active, updatedAt: DateTime.utc(2026, 10, 2, 11)),
      ),
    );

    await container.read(myPostStateProvider('job-123').notifier).retry();

    expect(container.read(myPostStateProvider('job-123')).requireValue.detail.status, JobStatus.active);
  });

  test('changing accounts replaces private detail and clears the previous account status', () async {
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: PublicJobDto.fixture().copyWith(status: .archived, updatedAt: DateTime.utc(2026, 10, 2, 10)),
      ),
    );
    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: .archived);
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(description: 'Current account detail', status: .active),
      ),
    );

    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-user');
    await container.pump();
    final current = await container.read(myPostStateProvider('job-123').future);

    expect(current.detail.description, 'Current account detail');
    expect(current.detail.status, JobStatus.active);
  });

  test('renewing a session for the same account keeps its loaded private detail', () async {
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);

    authState.currentSession = authState.currentSession!.copyWith(accessToken: 'renewed-access-token');
    await container.pump();

    verify(() => userRepository.getMyPostedJob(jobId: 'job-123')).called(1);
  });

  test('a previous account retry cannot replace the current account detail', () async {
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    final previousResponse = Completer<ApiEnvelopeDto<UserJobDto>>();
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer((_) => previousResponse.future);
    final retry = container.read(myPostStateProvider('job-123').notifier).retry();
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(description: 'Current account detail', status: .active),
      ),
    );
    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-user');
    await container.pump();
    previousResponse.complete(
      ApiEnvelopeDto.fixture(data: UserJobDto.fixture().copyWith(description: 'Previous account detail')),
    );
    await retry;
    final current = await container.read(myPostStateProvider('job-123').future);

    expect(current.detail.description, 'Current account detail');
  });

  test('a previous account mutation cannot change the current account detail', () async {
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    final archiveResponse = Completer<ApiEnvelopeDto<PublicJobDto>>();
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer((_) => archiveResponse.future);
    final archive = container.read(myPostStateProvider('job-123').notifier).changeStatus(status: .archived);
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(description: 'Current account detail', status: .active),
      ),
    );
    authState.currentSession = AuthSessionDto.fixture().copyWith(userId: 'second-user');
    await container.pump();
    archiveResponse.complete(
      ApiEnvelopeDto.fixture(
        data: PublicJobDto.fixture().copyWith(status: .archived, updatedAt: DateTime.utc(2026, 10, 2, 10)),
      ),
    );
    await archive;
    final current = await container.read(myPostStateProvider('job-123').future);

    expect(current.detail.description, 'Current account detail');
    expect(current.detail.status, JobStatus.active);
    verifyNever(() => feedRepository.getFeedJobs(cursor: any(named: 'cursor')));
  });

  test('failed activation keeps the loaded post archived', () async {
    when(() => jobRepository.archiveJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: PublicJobDto.fixture().copyWith(status: .archived, updatedAt: DateTime.utc(2026, 10, 2, 10)),
      ),
    );
    final failure = StateError('offline');
    when(() => jobRepository.activateJob(jobId: 'job-123')).thenThrow(failure);
    container.listen(myPostStateProvider('job-123'), (_, _) {});
    await container.read(myPostStateProvider('job-123').future);
    await container.read(myPostStateProvider('job-123').notifier).changeStatus(status: JobStatus.archived);

    await expectLater(
      container.read(myPostStateProvider('job-123').notifier).changeStatus(status: JobStatus.active),
      throwsA(same(failure)),
    );

    expect(container.read(myPostStateProvider('job-123')).requireValue.detail.status, JobStatus.archived);
  });
}
