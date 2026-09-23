import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'post_state.g.dart';

@riverpod
class PostState extends _$PostState {
  String? _idempotencyKey;

  @override
  PostData build() => const PostData();

  Future<void> publish() async {
    final postData = state;
    if (!postData.canPublish) return;

    final idempotencyKey = _idempotencyKey ??= const Uuid().v4();
    final jobRepository = ref.read(jobRepositoryProvider);
    final selectedLocation = postData.location;
    final ({double latitude, double longitude}) location;
    if (selectedLocation != null) {
      location = selectedLocation;
    } else {
      final addressSelection = postData.addressSelection!;
      final addressDetails = await ref
          .read(geosearchRepositoryProvider)
          .getAddressDetails(addressId: addressSelection.addressId, sessionToken: addressSelection.sessionToken);
      location = (latitude: addressDetails.latitude, longitude: addressDetails.longitude);
    }

    await jobRepository.createJob(
      description: postData.descriptionText!,
      latitude: location.latitude,
      longitude: location.longitude,
      contactMethod: postData.contact!.contactMethod,
      contactIdentifier: postData.contact!.identifier,
      idempotencyKey: idempotencyKey,
    );
  }

  void setDescription(String descriptionText) {
    final normalizedDescriptionText = descriptionText.isEmpty ? null : descriptionText;
    if (state.descriptionText == normalizedDescriptionText) return;

    state = state.copyWith(descriptionText: normalizedDescriptionText);
  }

  void selectContact({required JobContactMethod contactMethod, required String identifier}) {
    final contact = (contactMethod: contactMethod, identifier: identifier);
    if (state.contact == contact) return;

    state = state.copyWith(contact: contact);
  }

  void selectAddress({required String addressId, required String sessionToken, required String locationTitle}) {
    final addressSelection = (addressId: addressId, sessionToken: sessionToken);
    if (state.addressSelection == addressSelection && state.location == null && state.locationTitle == locationTitle) {
      return;
    }

    state = state.copyWith(addressSelection: addressSelection, location: null, locationTitle: locationTitle);
  }

  void clearSelectedAddress() {
    if (state.addressSelection == null) return;

    state = state.copyWith(addressSelection: null, locationTitle: state.location == null ? null : state.locationTitle);
  }

  void setLocation({required double latitude, required double longitude, required String locationTitle}) {
    final location = (latitude: latitude, longitude: longitude);
    if (state.location == location && state.addressSelection == null && state.locationTitle == locationTitle) {
      return;
    }

    state = state.copyWith(location: location, addressSelection: null, locationTitle: locationTitle);
  }

  void clearLocation() {
    if (state.location == null) return;

    state = state.copyWith(location: null, locationTitle: state.addressSelection == null ? null : state.locationTitle);
  }
}
