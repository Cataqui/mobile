import 'package:freezed_annotation/freezed_annotation.dart';

part 'onboarding_local_progress_dto.freezed.dart';
part 'onboarding_local_progress_dto.g.dart';

@freezed
abstract class OnboardingLocalProgressDto with _$OnboardingLocalProgressDto {
  const factory OnboardingLocalProgressDto({String? name, @Default(false) bool serverConfirmedCompleted}) =
      _OnboardingLocalProgressDto;

  const OnboardingLocalProgressDto._();

  factory OnboardingLocalProgressDto.fromJson(Map<String, Object?> json) => _$OnboardingLocalProgressDtoFromJson(json);

  bool get completed => serverConfirmedCompleted || (name?.trim().isNotEmpty ?? false);
}
