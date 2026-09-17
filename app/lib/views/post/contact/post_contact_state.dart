import 'package:cataqui_app/core/dtos/saved_contact_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/contact/post_contact_option.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_contact_state.g.dart';

@Riverpod(retry: PostContactState._noRetry)
class PostContactState extends _$PostContactState {
  static Duration? _noRetry(int retryCount, Object error) => null;

  @override
  Future<List<PostContactOption>> build() async {
    final envelope = await ref.watch(userRepositoryProvider).getContacts();

    return envelope.data.map(_createOption).toList(growable: false);
  }

  PostContactOption _createOption(SavedContactDto contact) {
    return PostContactOption(
      contact: contact,
      displayIdentifier: contact.contactMethod.displayIdentifier(contact.identifier),
    );
  }
}
