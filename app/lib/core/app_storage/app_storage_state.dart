import 'package:cataqui_app/core/app_storage/app_storage_data.dart';
import 'package:cataqui_app/core/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_storage_state.g.dart';

@Riverpod(keepAlive: true)
class AppStorageState extends _$AppStorageState {
  static const _seenSwipeFeedHintKey = 'seen_swipe_feed_hint';

  @override
  Future<AppStorageData> build() async {
    final prefs = ref.read(sharedPreferencesAsyncProvider);
    final hasSeenSwipeFeedHint = await prefs.getBool(_seenSwipeFeedHintKey) ?? false;

    return AppStorageData(hasSeenSwipeFeedHint: hasSeenSwipeFeedHint);
  }

  Future<void> setSeenSwipeFeedHint({required bool value}) async {
    if (state.value!.hasSeenSwipeFeedHint == value) return;

    final prefs = ref.read(sharedPreferencesAsyncProvider);
    await prefs.setBool(_seenSwipeFeedHintKey, value);

    state = AsyncData(state.value!.copyWith(hasSeenSwipeFeedHint: value));
  }
}
