part of 'qui_color_scheme.dart';

@immutable
class QuiColorsColorScheme {
  const QuiColorsColorScheme({
    required this.primary,
    required this.neutral,
    required this.orange,
    required this.teal,
    required this.cyan,
    required this.violet,
    required this.pink,
    required this.yellow,
    required this.whatsapp,
  });

  final QuiColorVariantColorScheme primary;
  final QuiColorVariantColorScheme neutral;
  final QuiColorVariantColorScheme orange;
  final QuiColorVariantColorScheme teal;
  final QuiColorVariantColorScheme cyan;
  final QuiColorVariantColorScheme violet;
  final QuiColorVariantColorScheme pink;
  final QuiColorVariantColorScheme yellow;
  final QuiColorVariantColorScheme whatsapp;

  QuiColorsColorScheme copyWith({
    QuiColorVariantColorScheme? primary,
    QuiColorVariantColorScheme? neutral,
    QuiColorVariantColorScheme? orange,
    QuiColorVariantColorScheme? teal,
    QuiColorVariantColorScheme? cyan,
    QuiColorVariantColorScheme? violet,
    QuiColorVariantColorScheme? pink,
    QuiColorVariantColorScheme? yellow,
    QuiColorVariantColorScheme? whatsapp,
  }) {
    return QuiColorsColorScheme(
      primary: primary ?? this.primary,
      neutral: neutral ?? this.neutral,
      orange: orange ?? this.orange,
      teal: teal ?? this.teal,
      cyan: cyan ?? this.cyan,
      violet: violet ?? this.violet,
      pink: pink ?? this.pink,
      yellow: yellow ?? this.yellow,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiColorsColorScheme &&
          primary == other.primary &&
          neutral == other.neutral &&
          orange == other.orange &&
          teal == other.teal &&
          cyan == other.cyan &&
          violet == other.violet &&
          pink == other.pink &&
          yellow == other.yellow &&
          whatsapp == other.whatsapp;

  @override
  int get hashCode => Object.hash(primary, neutral, orange, teal, cyan, violet, pink, yellow, whatsapp);

  static QuiColorsColorScheme lerp(QuiColorsColorScheme a, QuiColorsColorScheme b, double t) {
    return QuiColorsColorScheme(
      primary: QuiColorVariantColorScheme.lerp(a.primary, b.primary, t),
      neutral: QuiColorVariantColorScheme.lerp(a.neutral, b.neutral, t),
      orange: QuiColorVariantColorScheme.lerp(a.orange, b.orange, t),
      teal: QuiColorVariantColorScheme.lerp(a.teal, b.teal, t),
      cyan: QuiColorVariantColorScheme.lerp(a.cyan, b.cyan, t),
      violet: QuiColorVariantColorScheme.lerp(a.violet, b.violet, t),
      pink: QuiColorVariantColorScheme.lerp(a.pink, b.pink, t),
      yellow: QuiColorVariantColorScheme.lerp(a.yellow, b.yellow, t),
      whatsapp: QuiColorVariantColorScheme.lerp(a.whatsapp, b.whatsapp, t),
    );
  }
}

@immutable
class QuiColorVariantColorScheme {
  const QuiColorVariantColorScheme({
    required this.solid,
    required this.hover,
    required this.pressed,
    required this.subtle,
    required this.subtleHover,
    required this.subtlePressed,
    required this.text,
    required this.border,
    required this.onSolid,
  });

  final Color solid;
  final Color hover;
  final Color pressed;
  final Color subtle;
  final Color subtleHover;
  final Color subtlePressed;
  final Color text;
  final Color border;
  final Color onSolid;

  QuiColorVariantColorScheme copyWith({
    Color? solid,
    Color? hover,
    Color? pressed,
    Color? subtle,
    Color? subtleHover,
    Color? subtlePressed,
    Color? text,
    Color? border,
    Color? onSolid,
  }) {
    return QuiColorVariantColorScheme(
      solid: solid ?? this.solid,
      hover: hover ?? this.hover,
      pressed: pressed ?? this.pressed,
      subtle: subtle ?? this.subtle,
      subtleHover: subtleHover ?? this.subtleHover,
      subtlePressed: subtlePressed ?? this.subtlePressed,
      text: text ?? this.text,
      border: border ?? this.border,
      onSolid: onSolid ?? this.onSolid,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is QuiColorVariantColorScheme &&
          solid == other.solid &&
          hover == other.hover &&
          pressed == other.pressed &&
          subtle == other.subtle &&
          subtleHover == other.subtleHover &&
          subtlePressed == other.subtlePressed &&
          text == other.text &&
          border == other.border &&
          onSolid == other.onSolid;

  @override
  int get hashCode => Object.hash(solid, hover, pressed, subtle, subtleHover, subtlePressed, text, border, onSolid);

  static QuiColorVariantColorScheme lerp(QuiColorVariantColorScheme a, QuiColorVariantColorScheme b, double t) {
    return QuiColorVariantColorScheme(
      solid: Color.lerp(a.solid, b.solid, t)!,
      hover: Color.lerp(a.hover, b.hover, t)!,
      pressed: Color.lerp(a.pressed, b.pressed, t)!,
      subtle: Color.lerp(a.subtle, b.subtle, t)!,
      subtleHover: Color.lerp(a.subtleHover, b.subtleHover, t)!,
      subtlePressed: Color.lerp(a.subtlePressed, b.subtlePressed, t)!,
      text: Color.lerp(a.text, b.text, t)!,
      border: Color.lerp(a.border, b.border, t)!,
      onSolid: Color.lerp(a.onSolid, b.onSolid, t)!,
    );
  }
}
