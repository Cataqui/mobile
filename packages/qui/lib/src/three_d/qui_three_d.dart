import 'package:flutter/material.dart';
import 'package:qui/gen/three_d.g.dart';

/// QUI-design-system 3D image assets.
///
///
/// ```dart
/// QuiThreeD.box(width: 200, height: 200);
/// await QuiThreeD.precache(context);
/// ```
abstract final class QuiThreeD {
  QuiThreeD._();

  /// A cardboard box illustration.
  static Widget box({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.box(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A brush illustration.
  static Widget brush({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.brush(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// Empty São Paulo cityscape illustration.
  static Widget emptyCitySaoPaulo({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.emptyCitySaoPaulo(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A hammer illustration.
  static Widget hammer({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.hammer(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A ladder illustration.
  static Widget ladder({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.ladder(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A location pin (front-facing) illustration.
  static Widget locationPinFront({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.locationPinFront(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A resting location pin illustration.
  static Widget locationPinResting({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.locationPinResting(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A cracked resting location pin illustration.
  static Widget locationPinRestingCracked({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.locationPinRestingCracked(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A motorcycle illustration.
  static Widget motorcycle({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.motorcycle(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A shopping cart illustration.
  static Widget shoppingCart({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.shoppingCart(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A small truck illustration.
  static Widget smallTruck({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.smallTruck(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A spilled coffee illustration.
  static Widget spilledCoffee({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.spilledCoffee(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A tool box illustration.
  static Widget toolBox({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.toolBox(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A wifi exclamation illustration (offline/no connection).
  static Widget wifiExclamation({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.wifiExclamation(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// A work items mess illustration.
  static Widget workItemsMess({
    Key? key,
    double? width,
    double? height,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    Color? color,
    BlendMode? colorBlendMode,
  }) => $ThreeD.workItemsMess(
    key: key,
    width: width,
    height: height,
    fit: fit,
    alignment: alignment,
    color: color,
    colorBlendMode: colorBlendMode,
  );

  /// Precaches all 3D images in this namespace.
  static Future<void> precache(BuildContext context) => $ThreeD.precache(context);
}
