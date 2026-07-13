part of 'qui_color_scheme.dart';

@immutable
class QuiButtonsColorScheme {
  const QuiButtonsColorScheme({
    required this.primary,
    required this.secondary,
    required this.tertiary,
    required this.text,
    required this.danger,
    required this.success,
    required this.floating,
    required this.whatsapp,
  });

  final QuiButtonColorScheme primary;
  final QuiButtonColorScheme secondary;
  final QuiButtonColorScheme tertiary;
  final QuiButtonColorScheme text;
  final QuiButtonColorScheme danger;
  final QuiButtonColorScheme success;
  final QuiFloatingButtonColorScheme floating;
  final QuiBrandedButtonColorScheme whatsapp;

  QuiButtonsColorScheme copyWith({
    QuiButtonColorScheme? primary,
    QuiButtonColorScheme? secondary,
    QuiButtonColorScheme? tertiary,
    QuiButtonColorScheme? text,
    QuiButtonColorScheme? danger,
    QuiButtonColorScheme? success,
    QuiFloatingButtonColorScheme? floating,
    QuiBrandedButtonColorScheme? whatsapp,
  }) {
    return QuiButtonsColorScheme(
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      tertiary: tertiary ?? this.tertiary,
      text: text ?? this.text,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      floating: floating ?? this.floating,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiButtonsColorScheme &&
          primary == other.primary &&
          secondary == other.secondary &&
          tertiary == other.tertiary &&
          text == other.text &&
          danger == other.danger &&
          success == other.success &&
          floating == other.floating &&
          whatsapp == other.whatsapp;

  @override
  int get hashCode => Object.hash(primary, secondary, tertiary, text, danger, success, floating, whatsapp);

  static QuiButtonsColorScheme lerp(QuiButtonsColorScheme a, QuiButtonsColorScheme b, double t) {
    return QuiButtonsColorScheme(
      primary: QuiButtonColorScheme.lerp(a.primary, b.primary, t),
      secondary: QuiButtonColorScheme.lerp(a.secondary, b.secondary, t),
      tertiary: QuiButtonColorScheme.lerp(a.tertiary, b.tertiary, t),
      text: QuiButtonColorScheme.lerp(a.text, b.text, t),
      danger: QuiButtonColorScheme.lerp(a.danger, b.danger, t),
      success: QuiButtonColorScheme.lerp(a.success, b.success, t),
      floating: QuiFloatingButtonColorScheme.lerp(a.floating, b.floating, t),
      whatsapp: QuiBrandedButtonColorScheme.lerp(a.whatsapp, b.whatsapp, t),
    );
  }
}
