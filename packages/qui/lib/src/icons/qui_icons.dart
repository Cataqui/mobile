// ignore_for_file: constant_identifier_names — QuiIcons is purposely UpperCamelCase for on-brand public API

import 'package:qui/gen/assets.gen.dart';

/// Type-safe accessors for every SVG icon bundled with the QUI design system.
///
/// `QuiIcons` mirrors the contents of `qui/assets/icons/`. Add a new `.svg`
/// file to that directory, run `melos gen:all`, and the accessor appears
/// here automatically — no manual edits required.
///
/// Each accessor returns an [SvgGenImage] that renders with `.svg()`:
///
/// ```dart
/// QuiIcons.cross.svg(
///   width: 16,
///   height: 16,
///   colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
/// );
/// ```
///
/// Store a reference with type inference:
///
/// ```dart
/// final icon = QuiIcons.magnifierGlass;
/// icon.svg(width: 20, height: 20);
/// ```
const QuiIcons = Assets.icons;
