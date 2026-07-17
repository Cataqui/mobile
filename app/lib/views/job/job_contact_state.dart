import 'package:cataqui_app/core/dtos/job_contact_dto.dart';
import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_contact_state.g.dart';

@riverpod
class JobContactState extends _$JobContactState {
  @override
  FutureOr<void> build({required String jobId, required String contactId}) {}

  Future<void> contact() async {
    state = const AsyncLoading<void>();
    state = await AsyncValue.guard<void>(_performContact);
  }

  Future<void> _performContact() async {
    final envelope = await ref.read(jobRepositoryProvider).getJobContact(jobId: jobId, contactId: contactId);

    await _dispatch(contact: envelope.data);
  }

  Future<void> _dispatch({required JobContactDto contact}) async {
    switch (contact.contactMethod) {
      case JobContactMethod.whatsapp:
        await ref.read(whatsappProvider).launchChat(number: contact.identifier);
      case JobContactMethod.phoneCall:
        await ref.read(telephonyProvider).call(number: contact.identifier);
      case JobContactMethod.unknown:
        break;
    }
  }
}
