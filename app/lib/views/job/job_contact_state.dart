import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/job/job_contact_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_contact_state.g.dart';

@riverpod
class JobContactState extends _$JobContactState {
  @override
  Future<JobContactData> build({required String jobId, required String contactId}) {
    return _fetchJobContact();
  }

  Future<void> retry() async {
    state = const AsyncLoading<JobContactData>();
    state = await AsyncValue.guard(_fetchJobContact);
  }

  Future<JobContactData> _fetchJobContact() async {
    final jobRepository = ref.read(jobRepositoryProvider);

    final envelope = await jobRepository.getJobContact(jobId: jobId, contactId: contactId);

    return JobContactData(contact: envelope.data);
  }
}
