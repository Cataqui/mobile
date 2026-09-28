import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:job_map/src/enums/map_render_quality.dart';
import 'package:job_map/src/job_location_map_color_scheme.dart';
import 'package:job_map/src/job_location_map_style.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

@immutable
final class JobMapScene {
  const JobMapScene({
    required this.cameraLatitude,
    required this.cameraLongitude,
    required this.locationLatitude,
    required this.locationLongitude,
    required this.zoom,
    required this.radiusMeters,
    required this.radiusColorArgb,
    required this.backgroundColorArgb,
    required this.styleJson,
    required this.widthPoints,
    required this.heightPoints,
    required this.paddingBottomPoints,
    required this.widthPx,
    required this.heightPx,
    this.nativeScale = 1,
    this.devicePixelRatio,
  }) : assert(widthPx > 0, 'widthPx must be positive'),
       assert(heightPx > 0, 'heightPx must be positive'),
       assert(widthPoints > 0, 'widthPoints must be positive'),
       assert(heightPoints > 0, 'heightPoints must be positive'),
       assert(radiusMeters >= 0, 'radiusMeters must be non-negative'),
       assert(nativeScale == 1 || nativeScale == .5 || nativeScale == .25, 'nativeScale must be 1, .5, or .25');

  factory JobMapScene.fromContext({
    required BuildContext context,
    required ({double latitude, double longitude}) location,
    required double areaDiameterInMeters,
    required Size logicalSize,
    required double devicePixelRatio,
    double zoom = 13,
    Offset offset = Offset.zero,
    JobLocationMapColorScheme? colorScheme,
  }) {
    assert(devicePixelRatio > 0, 'devicePixelRatio must be positive');
    assert(logicalSize.width > 0 && logicalSize.height > 0, 'logicalSize must be positive');
    assert(location.latitude >= -90 && location.latitude <= 90, 'latitude must be between -90 and 90');
    assert(location.longitude >= -180 && location.longitude <= 180, 'longitude must be between -180 and 180');
    assert(areaDiameterInMeters >= 0, 'areaDiameterInMeters must be non-negative');

    final themeAppearance = colorScheme == null ? _appearanceFor(context) : null;
    final appearance = colorScheme ?? themeAppearance!.colorScheme;
    final styleJson =
        themeAppearance?.styleJson ?? JobLocationMapStyle.fromColorScheme(colorScheme: appearance).googleMapsJson;
    final effectiveOffset = offset + Offset(0, mapPadding.bottom / 2);
    final effectiveZoom = defaultTargetPlatform == .android ? zoom.roundToDouble() : zoom;
    final worldSize = 256 * math.pow(2, effectiveZoom);
    final degreesPerPixel = 360 / worldSize;
    final latitudeRadians = location.latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
    final worldX = location.longitude / 360 * worldSize;
    final worldY = -math.log(math.tan(math.pi / 4 + latitudeRadians / 2)) / (2 * math.pi) * worldSize;
    final radiusMeters = areaDiameterInMeters / 2;
    final radiusPoints = projectedRadiusPoints(
      radiusMeters: radiusMeters,
      latitude: location.latitude,
      zoom: effectiveZoom,
    );
    // Nearby jobs reuse the same Google camera while their circles keep their
    // actual coordinates. Wider horizontal cells leave the circle inside the card.
    final cameraCellSize = logicalSize.width / 4;
    final horizontalCameraCellSize = radiusPoints + effectiveOffset.dx.abs() <= cameraCellSize - 4
        ? logicalSize.width / 2
        : cameraCellSize;
    final cameraWorldX = (worldX / horizontalCameraCellSize).round() * horizontalCameraCellSize;
    final cameraWorldY = (worldY / cameraCellSize).round() * cameraCellSize;
    final cameraLatitude = math.atan(math.exp(-cameraWorldY / worldSize * 2 * math.pi)) * 360 / math.pi - 90;
    final cameraLongitude = cameraWorldX / worldSize * 360;
    final latitudeScale = math.max(math.cos(cameraLatitude * math.pi / 180).abs(), 0.01);
    const nativeScale = 1.0;
    final outputPixelRatio = math.min(devicePixelRatio * nativeScale, 1.5);

    return JobMapScene(
      cameraLatitude: cameraLatitude + effectiveOffset.dy * degreesPerPixel * latitudeScale,
      cameraLongitude: (cameraLongitude - effectiveOffset.dx * degreesPerPixel + 180) % 360 - 180,
      locationLatitude: location.latitude,
      locationLongitude: location.longitude,
      zoom: effectiveZoom,
      radiusMeters: radiusMeters,
      radiusColorArgb: appearance.locationRadius.toARGB32(),
      backgroundColorArgb: appearance.background.toARGB32(),
      styleJson: styleJson,
      widthPoints: logicalSize.width,
      heightPoints: logicalSize.height,
      paddingBottomPoints: mapPadding.bottom,
      widthPx: (logicalSize.width * outputPixelRatio).round().clamp(1, 1 << 30),
      heightPx: (logicalSize.height * outputPixelRatio).round().clamp(1, 1 << 30),
      nativeScale: nativeScale,
      devicePixelRatio: devicePixelRatio,
    );
  }

  static const mapPadding = EdgeInsets.only(bottom: 20);

  static double projectedRadiusPoints({required double radiusMeters, required double latitude, required double zoom}) {
    final worldSize = 256 * math.pow(2, zoom);
    final latitudeRadians = latitude.clamp(-85.05112878, 85.05112878) * math.pi / 180;
    return radiusMeters * worldSize / (2 * math.pi * 6378137 * math.cos(latitudeRadians));
  }

  static ({Brightness brightness, MateoPalette palette, JobLocationMapColorScheme colorScheme, String? styleJson})?
  _cachedAppearance;

  static ({JobLocationMapColorScheme colorScheme, String? styleJson}) _appearanceFor(BuildContext context) {
    final theme = MateoTheme.of(context);
    final cached = _cachedAppearance;
    if (cached != null && cached.brightness == theme.brightness && cached.palette == theme.palette) {
      return (colorScheme: cached.colorScheme, styleJson: cached.styleJson);
    }

    final colorScheme = JobLocationMapColorScheme.fromBrightness(brightness: theme.brightness, palette: theme.palette);
    final styleJson = JobLocationMapStyle.fromColorScheme(colorScheme: colorScheme).googleMapsJson;
    _cachedAppearance = (
      brightness: theme.brightness,
      palette: theme.palette,
      colorScheme: colorScheme,
      styleJson: styleJson,
    );
    return (colorScheme: colorScheme, styleJson: styleJson);
  }

  final double cameraLatitude;
  final double cameraLongitude;
  final double locationLatitude;
  final double locationLongitude;
  final double zoom;
  final double radiusMeters;
  final int radiusColorArgb;
  final int backgroundColorArgb;
  final String? styleJson;
  final double widthPoints;
  final double heightPoints;
  final double paddingBottomPoints;
  final int widthPx;
  final int heightPx;
  final double nativeScale;
  final double? devicePixelRatio;

  JobMapScene get basemap {
    if (radiusMeters == 0 &&
        radiusColorArgb == 0 &&
        locationLatitude == cameraLatitude &&
        locationLongitude == cameraLongitude) {
      return this;
    }
    return JobMapScene(
      cameraLatitude: cameraLatitude,
      cameraLongitude: cameraLongitude,
      locationLatitude: cameraLatitude,
      locationLongitude: cameraLongitude,
      zoom: zoom,
      radiusMeters: 0,
      radiusColorArgb: 0,
      backgroundColorArgb: backgroundColorArgb,
      styleJson: styleJson,
      widthPoints: widthPoints,
      heightPoints: heightPoints,
      paddingBottomPoints: paddingBottomPoints,
      widthPx: widthPx,
      heightPx: heightPx,
      nativeScale: nativeScale,
      devicePixelRatio: devicePixelRatio,
    );
  }

  JobMapScene withRenderQuality(MapRenderQuality quality) {
    if (quality == .balanced) return this;
    final displayDensity = devicePixelRatio ?? math.max(widthPx / widthPoints, heightPx / heightPoints) / nativeScale;
    final outputLimit = switch (quality) {
      .compact => 1.25,
      .balanced => 1.5,
      .sharp => 2.0,
    };
    final outputPixelRatio = math.min(displayDensity, outputLimit);
    return JobMapScene(
      cameraLatitude: cameraLatitude,
      cameraLongitude: cameraLongitude,
      locationLatitude: locationLatitude,
      locationLongitude: locationLongitude,
      zoom: zoom,
      radiusMeters: radiusMeters,
      radiusColorArgb: radiusColorArgb,
      backgroundColorArgb: backgroundColorArgb,
      styleJson: styleJson,
      widthPoints: widthPoints,
      heightPoints: heightPoints,
      paddingBottomPoints: paddingBottomPoints,
      widthPx: (widthPoints * outputPixelRatio).round().clamp(1, 1 << 30),
      heightPx: (heightPoints * outputPixelRatio).round().clamp(1, 1 << 30),
      nativeScale: 1,
      devicePixelRatio: devicePixelRatio,
    );
  }

  int get estimatedCachedBytes => widthPx * heightPx * 4 + estimatedPreviewBytes;

  double get previewScale => defaultTargetPlatform == .android ? math.min(nativeScale, .75) : nativeScale;

  int get estimatedPreviewBytes {
    final previewWidth = (widthPoints * previewScale).round().clamp(1, widthPx);
    final previewHeight = (heightPoints * previewScale).round().clamp(1, heightPx);
    return previewWidth * previewHeight * 4;
  }

  bool sharesBasemapWith(JobMapScene other) =>
      cameraLatitude == other.cameraLatitude &&
      cameraLongitude == other.cameraLongitude &&
      zoom == other.zoom &&
      backgroundColorArgb == other.backgroundColorArgb &&
      styleJson == other.styleJson &&
      widthPoints == other.widthPoints &&
      heightPoints == other.heightPoints &&
      nativeScale == other.nativeScale &&
      paddingBottomPoints == other.paddingBottomPoints;

  Object get _identity => (
    cameraLatitude,
    cameraLongitude,
    locationLatitude,
    locationLongitude,
    zoom,
    radiusMeters,
    radiusColorArgb,
    backgroundColorArgb,
    styleJson,
    widthPoints,
    heightPoints,
    paddingBottomPoints,
    widthPx,
    heightPx,
    nativeScale,
    devicePixelRatio,
  );

  @override
  bool operator ==(Object other) => other is JobMapScene && _identity == other._identity;

  @override
  int get hashCode => _identity.hashCode;
}
