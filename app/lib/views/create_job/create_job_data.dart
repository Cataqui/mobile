import 'package:cataqui_app/core/enums/job_enums.dart';
import 'package:cataqui_app/i18n/locale.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:intl/intl.dart';

part 'create_job_data.freezed.dart';

@freezed
abstract class CreateJobData with _$CreateJobData {
  const factory CreateJobData({
    required String currencyCode,
    String? descriptionText,
    String? jobId,
    @Default('0') String paymentMinimumAmount,
    @Default('0') String paymentMaximumAmount,
    @Default(JobPaymentType.fixed) JobPaymentType paymentType,
    @Default(false) bool isCreatingDraft,
  }) = _CreateJobData;

  const CreateJobData._();

  String currencySymbol(Translations i18n) {
    return NumberFormat.simpleCurrency(name: currencyCode, locale: i18n.$meta.locale.underscoreTag).currencySymbol;
  }
}
