import 'package:dio/dio.dart';

import '../exceptions/offline_connection_dio_exception.dart';

/// Shared helpers for [Object].
extension ObjectExtension on Object? {
  /// Returns `true` when this is a [DioException] whose [DioException.error]
  /// carries an [OfflineConnectionDioException].
  bool get isOfflineConnectionDioException {
    final self = this;
    return self is DioException && self.error is OfflineConnectionDioException;
  }
}
