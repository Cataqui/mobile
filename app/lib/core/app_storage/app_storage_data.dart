import 'package:flutter/foundation.dart';

@immutable
class AppStorageData {
  const AppStorageData({required this.hasSeenSwipeFeedHint});

  final bool hasSeenSwipeFeedHint;

  AppStorageData copyWith({bool? hasSeenSwipeFeedHint}) {
    return AppStorageData(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint ?? this.hasSeenSwipeFeedHint);
  }
}
