import 'package:cataqui_app/core/dtos/api_envelope_dto.dart';
import 'package:cataqui_app/core/dtos/user_job_dto.dart';
import 'package:cataqui_app/core/providers.dart';
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
    container = ProviderContainer(overrides: [userRepositoryProvider.overrideWithValue(userRepository)])
      ..listen(myPostStateProvider('job-123'), (_, _) {});
  });

  tearDown(() => container.dispose());

  test('loads the selected user job detail', () async {
    final detail = await container.read(myPostStateProvider('job-123').future);

    expect(detail.jobId, 'job-123');
    expect(detail.description, 'Detalhes do post');
    verify(() => userRepository.getMyPostedJob(jobId: 'job-123')).called(1);
  });
}
