// ignore_for_file: constant_identifier_names — Qui3d is purposely UpperCamelCase for on-brand public API

import 'package:qui/gen/assets.gen.dart';

/// Type-safe accessors for every 3D image asset bundled with the QUI design system.
///
///
/// Each accessor returns an [AssetGenImage] that renders with `.image()`:
///
/// ```dart
/// Qui3d.box.image(
///   width: 200,
///   height: 200,
/// );
/// ```
///
/// Store a reference with type inference:
///
/// ```dart
/// final asset = Qui3d.motorcycle;
/// asset.image(width: 300, height: 200);
/// ```
const Qui3d = Assets.threeD;
