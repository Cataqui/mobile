import 'package:cataqui_app/core/dtos/contact_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'job_contact_state.g.dart';

@riverpod
class JobContactState extends _$JobContactState {
  @override
  FutureOr<void> build({required String jobId, required String contactId}) {}

  Future<void> contact() async {
    state = const AsyncLoading<void>();
    final contactResult = await AsyncValue.guard<void>(_performContact);
    if (!ref.mounted) return;

    state = contactResult;
  }

  Future<void> _performContact() async {
    final envelope = await ref.read(jobRepositoryProvider).getJobContact(jobId: jobId, contactId: contactId);
    if (!ref.mounted) return;

    await _dispatch(contact: envelope.data);
  }

  Future<void> _dispatch({required ContactDto contact}) async {
    switch (contact.method) {
      case .whatsapp:
        final didOpenWhatsapp = await ref.read(whatsappProvider(identifier: contact.identifier)).chat();
        if (!didOpenWhatsapp) throw StateError('WhatsApp could not be opened.');
      case .phoneCall:
        final didOpenPhoneApp = await ref.read(phoneNumberProvider(value: contact.identifier)).call();
        if (!didOpenPhoneApp) throw StateError('The phone app could not be opened.');
      case .unknown:
        break;
    }
  }
}
