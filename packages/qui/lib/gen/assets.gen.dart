// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/arrow_rotate_clockwise.svg
  SvgGenImage get arrowRotateClockwise =>
      const SvgGenImage('assets/icons/arrow_rotate_clockwise.svg');

  /// File path: assets/icons/chevron_down.svg
  SvgGenImage get chevronDown =>
      const SvgGenImage('assets/icons/chevron_down.svg');

  /// File path: assets/icons/clock.svg
  SvgGenImage get clock => const SvgGenImage('assets/icons/clock.svg');

  /// File path: assets/icons/cross.svg
  SvgGenImage get cross => const SvgGenImage('assets/icons/cross.svg');

  /// File path: assets/icons/magnifier_glass.svg
  SvgGenImage get magnifierGlass =>
      const SvgGenImage('assets/icons/magnifier_glass.svg');

  /// File path: assets/icons/map_pin.svg
  SvgGenImage get mapPin => const SvgGenImage('assets/icons/map_pin.svg');

  /// File path: assets/icons/wrench.svg
  SvgGenImage get wrench => const SvgGenImage('assets/icons/wrench.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    arrowRotateClockwise,
    chevronDown,
    clock,
    cross,
    magnifierGlass,
    mapPin,
    wrench,
  ];
}

class $AssetsThreeDGen {
  const $AssetsThreeDGen();

  /// File path: assets/three_d/box.webp
  AssetGenImage get box => const AssetGenImage('assets/three_d/box.webp');

  /// File path: assets/three_d/brush.webp
  AssetGenImage get brush => const AssetGenImage('assets/three_d/brush.webp');

  /// File path: assets/three_d/empty_city_sao_paulo.webp
  AssetGenImage get emptyCitySaoPaulo =>
      const AssetGenImage('assets/three_d/empty_city_sao_paulo.webp');

  /// File path: assets/three_d/hammer.webp
  AssetGenImage get hammer => const AssetGenImage('assets/three_d/hammer.webp');

  /// File path: assets/three_d/ladder.webp
  AssetGenImage get ladder => const AssetGenImage('assets/three_d/ladder.webp');

  /// File path: assets/three_d/location_pin_front.webp
  AssetGenImage get locationPinFront =>
      const AssetGenImage('assets/three_d/location_pin_front.webp');

  /// File path: assets/three_d/location_pin_resting.webp
  AssetGenImage get locationPinResting =>
      const AssetGenImage('assets/three_d/location_pin_resting.webp');

  /// File path: assets/three_d/location_pin_resting_cracked.webp
  AssetGenImage get locationPinRestingCracked =>
      const AssetGenImage('assets/three_d/location_pin_resting_cracked.webp');

  /// File path: assets/three_d/motorcycle.webp
  AssetGenImage get motorcycle =>
      const AssetGenImage('assets/three_d/motorcycle.webp');

  /// File path: assets/three_d/shopping_cart.webp
  AssetGenImage get shoppingCart =>
      const AssetGenImage('assets/three_d/shopping_cart.webp');

  /// File path: assets/three_d/small_truck.webp
  AssetGenImage get smallTruck =>
      const AssetGenImage('assets/three_d/small_truck.webp');

  /// File path: assets/three_d/tool_box.webp
  AssetGenImage get toolBox =>
      const AssetGenImage('assets/three_d/tool_box.webp');

  /// File path: assets/three_d/wifi_exclamation.webp
  AssetGenImage get wifiExclamation =>
      const AssetGenImage('assets/three_d/wifi_exclamation.webp');

  /// File path: assets/three_d/work_items_mess.webp
  AssetGenImage get workItemsMess =>
      const AssetGenImage('assets/three_d/work_items_mess.webp');

  /// List of all assets
  List<AssetGenImage> get values => [
    box,
    brush,
    emptyCitySaoPaulo,
    hammer,
    ladder,
    locationPinFront,
    locationPinResting,
    locationPinRestingCracked,
    motorcycle,
    shoppingCart,
    smallTruck,
    toolBox,
    wifiExclamation,
    workItemsMess,
  ];
}

class Assets {
  const Assets._();

  static const String package = 'qui';

  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsThreeDGen threeD = $AssetsThreeDGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  static const String package = 'qui';

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    @Deprecated('Do not specify package for a generated library asset')
    String? package = package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({
    AssetBundle? bundle,
    @Deprecated('Do not specify package for a generated library asset')
    String? package = package,
  }) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => 'packages/qui/$_assetName';
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  static const String package = 'qui';

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    @Deprecated('Do not specify package for a generated library asset')
    String? package = package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => 'packages/qui/$_assetName';
}
