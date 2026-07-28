import 'package:cataqui_app/i18n/locale.dart';

class AppData {
  const AppData({required this.currentLocale});

  final AppLocale currentLocale;

  AppData copyWith({AppLocale? currentLocale}) {
    return AppData(currentLocale: currentLocale ?? this.currentLocale);
  }
}
