import 'package:cataqui_app/app_data.dart';
import 'package:locale/locale.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_state.g.dart';

@riverpod
class AppState extends _$AppState {
  @override
  AppData build() => const AppData(currentLocale: AppLocale.ptBr);

  void setLocale(AppLocale locale) {
    state = state.copyWith(currentLocale: locale);
  }
}
