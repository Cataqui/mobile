import 'package:cataqui_app/views/post/post_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'post_state.g.dart';

@riverpod
class PostState extends _$PostState {
  @override
  PostData build() => const PostData();

  void setDescription(String descriptionText) {
    final normalizedDescriptionText = descriptionText.isEmpty ? null : descriptionText;
    if (state.descriptionText == normalizedDescriptionText) return;

    state = state.copyWith(descriptionText: normalizedDescriptionText);
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

  void setPayment(String payment) {
    final trimmedPayment = payment.trim();
    final normalizedPayment = trimmedPayment.isEmpty ? null : trimmedPayment;
    if (state.payment == normalizedPayment) return;

    state = state.copyWith(payment: normalizedPayment);
  }
}
