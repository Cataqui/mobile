import 'package:cataqui_app/core/providers.dart';
import 'package:cataqui_app/views/welcome/welcome_view/welcome_data.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'welcome_state.g.dart';

@riverpod
class WelcomeState extends _$WelcomeState {
  @override
  WelcomeData build() => const WelcomeData();

  Future<void> fetchConnectedUserMetadata() async {
    if (state.metadata.isLoading) return;

    state = state.copyWith(metadata: const AsyncLoading());
    final result = await AsyncValue.guard(() async {
      final envelope = await ref.read(meRepositoryProvider).getMetadata();
      return envelope.data;
    });
    if (!ref.mounted) return;

    state = state.copyWith(metadata: result);
  }
}
