import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/me/my_post/my_post_data.dart';
import 'package:cataqui_app/views/me/my_post/my_post_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../mocks.dart';

void main() {
  late MockUserRepository userRepository;
  late ProviderContainer container;

  setUp(() {
    userRepository = MockUserRepository();
    when(() => userRepository.getMyPostedJob(jobId: 'job-123')).thenAnswer(
      (_) async => ApiEnvelopeDto.fixture(
        data: UserJobDto.fixture().copyWith(jobId: 'job-123', description: 'Detalhes do post'),
      ),
    );
    container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(userRepository)]);
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
          contact: const JobContactDto(contactMethod: JobContactMethod.unknown, identifier: 'other-contact'),
        ),
      ),
    );

    container.listen(myPostStateProvider('job-123'), (_, _) {});
    final data = await container.read(myPostStateProvider('job-123').future);

    expect(data.contactLabel, 'other-contact');
  });
}
