part of 'qui_color_scheme.dart';

/// Reusable semantic color families shared across QUI.
///
/// These families are the right source when app UI needs a semantic color set
/// before choosing a specific component pattern. Each property is a full
/// [QuiColorVariantColorScheme] that carries solid, subtle, text, and border
/// roles for the same semantic family.
@immutable
class QuiColorsColorScheme {
  /// Creates reusable semantic color families shared across QUI.
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

  /// {@macro qui_color_scheme_lerp}
  factory QuiColorsColorScheme.lerp(QuiColorsColorScheme a, QuiColorsColorScheme b, double t) {
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

  /// Semantic family for the active app primary brand slot.
  final QuiColorVariantColorScheme primary;

  /// Semantic family for neutral and ink-like treatments.
  final QuiColorVariantColorScheme neutral;

  /// Semantic family for orange accents.
  final QuiColorVariantColorScheme orange;

  /// Semantic family for teal accents.
  final QuiColorVariantColorScheme teal;

  /// Semantic family for cyan accents.
  final QuiColorVariantColorScheme cyan;

  /// Semantic family for violet accents.
  final QuiColorVariantColorScheme violet;

  /// Semantic family for pink accents.
  final QuiColorVariantColorScheme pink;

  /// Semantic family for yellow accents.
  final QuiColorVariantColorScheme yellow;

  /// Semantic family for WhatsApp-branded treatments.
  final QuiColorVariantColorScheme whatsapp;

  /// {@macro qui_color_scheme_copy_with}
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
}

/// A complete semantic color family for one role or brand.
///
/// This object keeps the related roles for one family together so app code can
/// choose the correct color for a fill, interaction state, text, or border. It
/// is appropriate for semantic families such as primary, success, neutral, or
/// branded accents.
@immutable
class QuiColorVariantColorScheme {
  /// Creates a semantic family for one role or brand.
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

  /// {@macro qui_color_scheme_lerp}
  factory QuiColorVariantColorScheme.lerp(QuiColorVariantColorScheme a, QuiColorVariantColorScheme b, double t) {
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

  /// Solid fill color for the family.
  final Color solid;

  /// Solid fill color used during hover interaction.
  final Color hover;

  /// Solid fill color used during pressed interaction.
  final Color pressed;

  /// Subtle background or tint color for the family.
  final Color subtle;

  /// Subtle background or tint color used during hover interaction.
  final Color subtleHover;

  /// Subtle background or tint color used during pressed interaction.
  final Color subtlePressed;

  /// Text color associated with this family on light or neutral surfaces.
  final Color text;

  /// Border color associated with this family.
  final Color border;

  /// Readable foreground color placed on top of [solid], [hover], or [pressed].
  final Color onSolid;

  /// {@macro qui_color_scheme_copy_with}
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
}
