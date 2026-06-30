import 'package:cataqui_app/app_state.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_state.g.dart';

@riverpod
class JobState extends _$JobState {
  @override
  Future<JobData> build(String jobId) {
    return _fetchJob();
  }

  Future<void> retry() async {
    state = const AsyncLoading<JobData>();
    state = await AsyncValue.guard(_fetchJob);
  }

  Future<JobData> _fetchJob() async {
    final jobRepository = ref.read(jobRepositoryProvider);
    final locale = ref.read(appStateProvider).currentLocale;
    final envelope = await jobRepository.getJob(jobId: jobId, locale: locale);

    return JobData(job: envelope.data);
  }
}
