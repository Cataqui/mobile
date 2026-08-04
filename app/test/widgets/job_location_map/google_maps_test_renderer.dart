import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

// Test infrastructure rather than a mock of Cataqui domain behavior. It
// records the native map boundary configuration and supplies a stable Flutter
// surface for widget and golden tests.
class GoogleMapsTestRenderer extends GoogleMapsFlutterPlatform {
  GoogleMapsTestRenderer({this.renderMapSurface = true}) : _previousPlatform = GoogleMapsFlutterPlatform.instance;

  final List<int> createdIds = <int>[];
  final List<MapWidgetConfiguration> widgetConfigurations = <MapWidgetConfiguration>[];
  final List<MapConfiguration> mapConfigurations = <MapConfiguration>[];
  final List<MapObjects> mapObjects = <MapObjects>[];
  final GoogleMapsFlutterPlatform _previousPlatform;
  final bool renderMapSurface;

  MapWidgetConfiguration get lastWidgetConfiguration => widgetConfigurations.last;
  MapConfiguration get lastMapConfiguration => mapConfigurations.last;
  MapObjects get lastMapObjects => mapObjects.last;

  void install() {
    GoogleMapsFlutterPlatform.instance = this;
  }

  void restore() {
    if (!identical(GoogleMapsFlutterPlatform.instance, this)) return;

    GoogleMapsFlutterPlatform.instance = _previousPlatform;
  }

  List<Map<String, Object?>> _decodeStyle(String? source) {
    if (source == null) return const [];

    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return const [];
    }
    if (decoded is! List<Object?>) return const [];

    return decoded.whereType<Map<String, Object?>>().toList();
  }

  Color _styleColor({
    required List<Map<String, Object?>> rules,
    required String featureType,
    required String elementType,
    required Color fallback,
  }) {
    for (final rule in rules.reversed) {
      if (rule['featureType'] != featureType || rule['elementType'] != elementType) continue;

      final stylers = rule['stylers'];
      if (stylers is! List<Object?>) continue;

      for (final styler in stylers.whereType<Map<String, Object?>>()) {
        final color = styler['color'];
        if (color is! String || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color)) continue;

        return Color(int.parse('FF${color.substring(1)}', radix: 16));
      }
    }

    return fallback;
  }

  @override
  Widget buildViewWithConfiguration(
    int creationId,
    PlatformViewCreatedCallback onPlatformViewCreated, {
    required MapWidgetConfiguration widgetConfiguration,
    MapObjects mapObjects = const MapObjects(),
    MapConfiguration mapConfiguration = const MapConfiguration(),
  }) {
    createdIds.add(creationId);
    widgetConfigurations.add(widgetConfiguration);
    mapConfigurations.add(mapConfiguration);
    this.mapObjects.add(mapObjects);

    return Builder(
      builder: (context) {
        final mapColorScheme = context.mateo.colorScheme.map;
        final rules = _decodeStyle(mapConfiguration.style);
        final backgroundColor = _styleColor(
          rules: rules,
          featureType: 'all',
          elementType: 'geometry',
          fallback: mapColorScheme.background,
        );
        if (!renderMapSurface) return ColoredBox(color: backgroundColor);

        final circle = mapObjects.circles.isEmpty ? null : mapObjects.circles.first;
        final circleDiameter = circle == null ? 0.0 : (circle.radius / 10).clamp(48.0, 160.0);
        final parkColor = _styleColor(
          rules: rules,
          featureType: 'poi.park',
          elementType: 'geometry',
          fallback: mapColorScheme.park,
        );
        final waterColor = _styleColor(
          rules: rules,
          featureType: 'water',
          elementType: 'geometry',
          fallback: mapColorScheme.water,
        );
        final businessColor = _styleColor(
          rules: rules,
          featureType: 'poi.business',
          elementType: 'geometry',
          fallback: mapColorScheme.landuseBusiness,
        );
        final attractionColor = _styleColor(
          rules: rules,
          featureType: 'poi.attraction',
          elementType: 'geometry',
          fallback: mapColorScheme.landuse,
        );
        final roadColor = _styleColor(
          rules: rules,
          featureType: 'road',
          elementType: 'geometry.fill',
          fallback: mapColorScheme.road,
        );
        final roadOutlineColor = _styleColor(
          rules: rules,
          featureType: 'road',
          elementType: 'geometry.stroke',
          fallback: mapColorScheme.buildingOutline,
        );
        final transitColor = _styleColor(
          rules: rules,
          featureType: 'transit.line',
          elementType: 'geometry',
          fallback: mapColorScheme.tunnel,
        );
        return ColoredBox(
          key: ValueKey<String>('google_maps_test_renderer_$creationId'),
          color: backgroundColor,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                left: -30,
                top: 80,
                width: 210,
                height: 130,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: parkColor, shape: BoxShape.circle),
                ),
              ),
              Positioned(
                right: -55,
                bottom: -95,
                width: 220,
                height: 260,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: waterColor, shape: BoxShape.circle),
                ),
              ),
              Positioned(
                left: 210,
                top: 24,
                width: 100,
                height: 72,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: businessColor, borderRadius: BorderRadius.circular(24)),
                ),
              ),
              Positioned(
                left: 36,
                bottom: 20,
                width: 74,
                height: 58,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: attractionColor, borderRadius: BorderRadius.circular(29)),
                ),
              ),
              Align(
                alignment: const Alignment(-0.15, 0.1),
                child: Transform.rotate(
                  angle: 0.72,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: transitColor, borderRadius: BorderRadius.circular(999)),
                    child: const SizedBox(width: 360, height: 6),
                  ),
                ),
              ),
              Align(
                alignment: const Alignment(0.25, -0.15),
                child: Transform.rotate(
                  angle: -0.22,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: roadColor,
                      border: Border.all(color: roadOutlineColor),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const SizedBox(width: 420, height: 18),
                  ),
                ),
              ),
              if (circle != null)
                Align(
                  alignment: const Alignment(0, 0.08),
                  child: DecoratedBox(
                    key: ValueKey<String>('google_maps_test_circle_$creationId'),
                    decoration: BoxDecoration(color: circle.fillColor, shape: BoxShape.circle),
                    child: SizedBox.square(dimension: circleDiameter),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
