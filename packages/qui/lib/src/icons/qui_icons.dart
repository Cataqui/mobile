import 'package:flutter/material.dart';
import 'package:qui/gen/icons.g.dart';

/// QUI-design-system icons.
///
/// Each static method returns a [Widget] rendered via a [CustomPainter]
/// — no runtime SVG parser dependency.
///
/// All current icons are monochrome; the `color` param recolors the entire
/// icon.
///
/// ```dart
/// QuiIcon.cross(width: 16, height: 16, color: Colors.red);
/// ```
abstract final class QuiIcon {
  QuiIcon._();

  /// Arrow pointing left.
  static Widget arrowLeft({Key? key, double? width, double? height, Color? color}) =>
      $Icons.arrowLeft(key: key, width: width, height: height, color1: color);

  /// Circular arrow (retry/refresh).
  static Widget arrowRotateClockwise({Key? key, double? width, double? height, Color? color}) =>
      $Icons.arrowRotateClockwise(key: key, width: width, height: height, color1: color);

  /// Arrow pointing up.
  static Widget arrowUp({Key? key, double? width, double? height, Color? color}) =>
      $Icons.arrowUp(key: key, width: width, height: height, color1: color);

  /// Chevron pointing down.
  static Widget chevronDown({Key? key, double? width, double? height, Color? color}) =>
      $Icons.chevronDown(key: key, width: width, height: height, color1: color);

  /// Blocked / circle-slash icon.
  static Widget circleBlock({Key? key, double? width, double? height, Color? color}) =>
      $Icons.circleBlock(key: key, width: width, height: height, color1: color);

  /// Clock icon.
  static Widget clock({Key? key, double? width, double? height, Color? color}) =>
      $Icons.clock(key: key, width: width, height: height, color1: color);

  /// Close / cross icon.
  static Widget cross({Key? key, double? width, double? height, Color? color}) =>
      $Icons.cross(key: key, width: width, height: height, color1: color);

  /// Exclamation circle icon.
  static Widget exclamationCircle({Key? key, double? width, double? height, Color? color}) =>
      $Icons.exclamationCircle(key: key, width: width, height: height, color1: color);

  /// Exclamation triangle icon.
  static Widget exclamationTriangle({Key? key, double? width, double? height, Color? color}) =>
      $Icons.exclamationTriangle(key: key, width: width, height: height, color1: color);

  /// Magnifying glass icon.
  static Widget magnifierGlass({Key? key, double? width, double? height, Color? color}) =>
      $Icons.magnifierGlass(key: key, width: width, height: height, color1: color);

  /// Map pin icon.
  static Widget mapPin({Key? key, double? width, double? height, Color? color}) =>
      $Icons.mapPin(key: key, width: width, height: height, color1: color);

  /// Phone handset icon.
  static Widget phone({Key? key, double? width, double? height, Color? color}) =>
      $Icons.phone(key: key, width: width, height: height, color1: color);

  /// Pointer hand pointing up icon.
  static Widget pointerHandUp({Key? key, double? width, double? height, Color? color}) =>
      $Icons.pointerHandUp(key: key, width: width, height: height, color1: color);

  /// Smartphone icon.
  static Widget smartphone({Key? key, double? width, double? height, Color? color}) =>
      $Icons.smartphone(key: key, width: width, height: height, color1: color);

  /// WhatsApp icon.
  static Widget whatsapp({Key? key, double? width, double? height, Color? color}) =>
      $Icons.whatsapp(key: key, width: width, height: height, color1: color);

  /// Wrench / tool icon.
  static Widget wrench({Key? key, double? width, double? height, Color? color}) =>
      $Icons.wrench(key: key, width: width, height: height, color1: color);
}
