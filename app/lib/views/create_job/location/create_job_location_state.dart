import 'package:cataqui_app/core/dtos/address_search_response_dto.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/create_job/create_job_state.dart';
import 'package:cataqui_app/views/create_job/location/create_job_location_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';

part 'create_job_location_state.g.dart';

@riverpod
class CreateJobLocationState extends _$CreateJobLocationState {
  final Uuid _uuid = const Uuid();
  late Debouncer<AddressSearchResponseDto> _addressSearchDebouncer;
  String? _currentQuery;
  String? _sessionToken;

  @override
  CreateJobLocationData build() {
    ref.watch(createJobStateProvider.select((createJobData) => createJobData.jobId));

    final addressSearchDebouncer = Debouncer<AddressSearchResponseDto>(delay: const Duration(milliseconds: 300));
    _addressSearchDebouncer = addressSearchDebouncer;
    _currentQuery = null;
    _sessionToken = null;

    ref.onDispose(() {
      addressSearchDebouncer.dispose();
      _sessionToken = null;
    });

    return const CreateJobLocationData();
  }

  Future<void> searchAddresses({required String query}) async {
    final normalizedQuery = query.trim();
    if (normalizedQuery == _currentQuery) return;

    _currentQuery = normalizedQuery;

    if (normalizedQuery.isEmpty) {
      _addressSearchDebouncer.cancel();
      _sessionToken = null;
      state = const CreateJobLocationData();
      return;
    }

    try {
      final response = await _addressSearchDebouncer(() {
        state = state.copyWith(addressSearch: const AsyncLoading<AddressSearchResponseDto?>());

        return ref
            .read(geosearchRepositoryProvider)
            .searchAddresses(query: normalizedQuery, sessionToken: _sessionToken ??= _uuid.v4());
      });

      if (!ref.mounted) return;

      state = state.copyWith(addressSearch: AsyncData<AddressSearchResponseDto?>(response));
    } on DebouncerCanceledException {
      return;
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;

      state = state.copyWith(addressSearch: AsyncError<AddressSearchResponseDto?>(error, stackTrace));
    }
  }

  void selectAddress({required String addressId}) {
    final sessionToken = _sessionToken;
    if (sessionToken == null) return;

    _addressSearchDebouncer.cancel();
    _sessionToken = null;
    ref.read(createJobStateProvider.notifier).setAddressSelection(addressId: addressId, sessionToken: sessionToken);
  }
}
