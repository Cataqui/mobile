import 'dart:async';

import 'package:cataqui_app/core/app_auth/app_auth_state.dart';
import 'package:cataqui_app/core/dtos/public_job_dto.dart';
import 'package:cataqui_app/core/enums/contact_method.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/feed/feed_state.dart';
import 'package:cataqui_app/views/me/my_posts_state.dart';
import 'package:cataqui_app/views/post/post_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show KeepAliveLink;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'post_state.g.dart';

@riverpod
class PostState extends _$PostState {
  String? _idempotencyKey;
  KeepAliveLink? _publicationKeepAliveLink;
  ({String addressId, double latitude, double longitude})? _resolvedAddress;

  @override
  PostData build() {
    _idempotencyKey = null;
    _publicationKeepAliveLink = null;
    _resolvedAddress = null;
    final draftRef = ref;
    // Background drafts must observe account changes while their provider is paused.
    final authenticationSubscription = draftRef.container.listen<String?>(
      appAuthStateProvider.select((session) => session?.userId),
      (previousUserId, userId) {
        if (previousUserId != null && previousUserId != userId) draftRef.invalidateSelf();
      },
    );
    draftRef.onDispose(authenticationSubscription.close);
    draftRef.onResume(() {
      scheduleMicrotask(() {
        if (!draftRef.mounted || state.isPublishing) return;
        _publicationKeepAliveLink?.close();
        _publicationKeepAliveLink = null;
      });
    });

    return const PostData();
  }

  Future<PublicJobDto?> publish() async {
    final postData = state;
    if (!postData.canPublish) return null;

    final publicationRef = ref;
    _publicationKeepAliveLink ??= publicationRef.keepAlive();
    var publicationSucceeded = false;
    state = state.copyWith(isPublishing: true);

    try {
      final idempotencyKey = _idempotencyKey ??= const Uuid().v4();
      final jobRepository = ref.read(jobRepositoryProvider);
      final location = await _getPublicationCoordinates(postData);
      if (!publicationRef.mounted) return null;

      final postedJob = await jobRepository.createJob(
        description: postData.descriptionText!,
        latitude: location.latitude,
        longitude: location.longitude,
        locationTitle: postData.locationTitle!.trim(),
        contactMethod: postData.contact!.contactMethod,
        contactIdentifier: postData.contact!.identifier,
        idempotencyKey: idempotencyKey,
      );
      if (!publicationRef.mounted) return null;
      publicationRef.read(feedStateProvider.notifier).injectJob(postedJob.data);
      publicationRef.invalidate(myPostsStateProvider);
      _idempotencyKey = null;
      _resolvedAddress = null;
      state = const PostData();
      publicationSucceeded = true;
      return postedJob.data;
    } on Object {
      if (!publicationRef.mounted) return null;
      rethrow;
    } finally {
      if (publicationRef.mounted) {
        state = state.copyWith(isPublishing: false);
        if (publicationSucceeded || !publicationRef.isPaused) {
          _publicationKeepAliveLink?.close();
          _publicationKeepAliveLink = null;
        }
      }
    }
  }

  void setDescription(String descriptionText) {
    final normalizedDescriptionText = descriptionText.isEmpty ? null : descriptionText;
    if (state.descriptionText == normalizedDescriptionText) return;

    if (state.descriptionText?.trim() != normalizedDescriptionText?.trim()) {
      _idempotencyKey = null;
    }
    state = state.copyWith(descriptionText: normalizedDescriptionText);
  }

  void selectContact({required ContactMethod contactMethod, required String identifier}) {
    final contact = (contactMethod: contactMethod, identifier: identifier);
    if (state.contact == contact) return;

    _idempotencyKey = null;
    state = state.copyWith(contact: contact);
  }

  void selectAddress({required String addressId, required String sessionToken, required String locationTitle}) {
    final addressSelection = (addressId: addressId, sessionToken: sessionToken);
    if (state.addressSelection == addressSelection && state.location == null && state.locationTitle == locationTitle) {
      return;
    }

    _idempotencyKey = null;
    state = state.copyWith(addressSelection: addressSelection, location: null, locationTitle: locationTitle);
  }

  void setLocation({required double latitude, required double longitude, required String locationTitle}) {
    final location = (latitude: latitude, longitude: longitude);
    if (state.location == location && state.addressSelection == null && state.locationTitle == locationTitle) {
      return;
    }

    _idempotencyKey = null;
    state = state.copyWith(location: location, addressSelection: null, locationTitle: locationTitle);
  }

  Future<({double latitude, double longitude})> _getPublicationCoordinates(PostData postData) async {
    final selectedLocation = postData.location;
    if (selectedLocation != null) return selectedLocation;

    final addressSelection = postData.addressSelection!;
    final resolvedAddress = _resolvedAddress;
    if (resolvedAddress != null && resolvedAddress.addressId == addressSelection.addressId) {
      return (latitude: resolvedAddress.latitude, longitude: resolvedAddress.longitude);
    }

    final locationRef = ref;
    final addressDetails = await locationRef
        .read(mapsRepositoryProvider)
        .getAddressDetails(addressId: addressSelection.addressId, sessionToken: addressSelection.sessionToken);
    if (locationRef.mounted) {
      _resolvedAddress = (
        addressId: addressSelection.addressId,
        latitude: addressDetails.latitude,
        longitude: addressDetails.longitude,
      );
    }
    return (latitude: addressDetails.latitude, longitude: addressDetails.longitude);
  }
}
