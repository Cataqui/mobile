import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:oh_my_flutter/oh_my_flutter.dart';
import 'package:qui/src/theme/map_style/qui_map_style.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'radius_style.dart';

/// Static vector map that highlights an approximate location radius.
///
/// `QuiLocationRadiusMap` is designed for location disclosure
/// experiences where the app should show the general area of a post, host, or
/// opportunity without exposing an exact pin. The map is intentionally
/// non-interactive: users cannot pan, zoom, rotate, or pinch it. It behaves like
/// a live map snapshot rendered from vector tiles.
///
/// The widget uses the package light map style bundled in `qui` and injects the
/// provided [tileUrlTemplate] at runtime. The tile source is expected to be
/// OpenMapTiles-like and to expose an `openmaptiles` source with common layers
/// such as `transportation`, `transportation_name`, and `place`.
///
/// For the best compatibility and performance, you should deploy or
/// fork the Protomap Worker at `https://github.com/Cataqui/protomap-worker` and
/// pass its vector tile endpoint as [tileUrlTemplate]. But you are not
/// required to use that worker: any common map tile server can be used as long
/// as it returns standard MVT vector tiles with layers compatible with the
/// bundled `qui` map style.
///
/// `QuiLocationRadiusMap` sizes itself from its parent. Place it in a bounded
/// parent such as [SizedBox], [AspectRatio], or a constrained layout region.
/// This keeps the widget flexible for cards, feed cells, sheets, and responsive
/// layouts.
class QuiLocationRadiusMap extends StatefulWidget {
  /// Creates a static vector-tile map centered around [location].
  ///
  /// The [tileUrlTemplate] must contain `{z}`, `{x}`, and `{y}` placeholders.
  /// Example:
  ///
  /// ```dart
  /// QuiLocationRadiusMap(
  ///   tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
  ///   location: (latitude: -23.55052, longitude: -46.633308),
  ///   fontConfig: (fontStack: 'Inter Regular', glyphUrlTemplate: 'https://.../{fontstack}/{range}.pbf'),
  ///   radiusInMeters: 500,
  /// )
  /// ```
  QuiLocationRadiusMap({
    required this.tileUrlTemplate,
    required this.location,
    required this.radiusInMeters,
    required this.fontConfig,
    super.key,
    this.radiusStyle = const RadiusStyle(),
    this.tileMinZoom = 1,
    this.tileMaxZoom = 14,
    this.zoom,
    this.offset = Offset.zero,
  }) : assert(location.latitude >= -90 && location.latitude <= 90, 'location.latitude must be between -90 and 90'),
       assert(
         location.longitude >= -180 && location.longitude <= 180,
         'location.longitude must be between -180 and 180',
       ),
       assert(radiusInMeters >= 0, 'radiusInMeters must be greater than or equal to zero'),
       assert(tileMinZoom >= 0, 'tileMinZoom must be greater than or equal to zero'),
       assert(tileMaxZoom > 0, 'tileMaxZoom must be greater than zero'),
       assert(tileMinZoom <= tileMaxZoom, 'tileMinZoom must be less than or equal to tileMaxZoom'),
       assert(zoom == null || zoom >= tileMinZoom, 'zoom must be greater than or equal to tileMinZoom'),
       assert(offset.isFinite, 'offset must be finite and not NaN');

  static const _minimumFitRadiusInMeters = 50.0;

  /// Vector tile URL template used to fetch map tiles.
  ///
  /// The template must include `{z}`, `{x}`, and `{y}` placeholders. Signed
  /// URLs, API keys, cache-busting query parameters, and provider-specific
  /// parameters should be supplied by the consuming app at runtime, ideally
  /// via query parameters (e.g. adding `?key=abcdef123456` to [tileUrlTemplate]).
  ///
  /// You should prefer an endpoint deployed from
  /// `https://github.com/Cataqui/protomap-worker` for the most predictable
  /// schema compatibility and runtime performance. Other map tile servers are
  /// supported when they return standard MVT vector tiles that match the style's
  /// expected OpenMapTiles-like layers.
  final String tileUrlTemplate;

  /// Center point of the radius circle.
  ///
  /// The map camera is centered on this point. The point itself is not rendered
  /// as a pin; only the surrounding radius is shown.
  final ({double latitude, double longitude}) location;

  /// Diameter of the visible radius circle in meters.
  ///
  /// This value represents the full extent from one edge of the circle to
  /// the opposite edge — it is the total visible span, not a mathematical
  /// centre-to-edge radius. For example, passing `500` means the circle
  /// covers an area 500 meters across (extreme to extreme).
  ///
  /// When [zoom] is not provided, the map automatically chooses an initial
  /// camera fit that attempts to keep this diameter visible while respecting
  /// [tileMinZoom] and [tileMaxZoom].
  final double radiusInMeters;

  /// Styling for the radius circle drawn over the map.
  final RadiusStyle radiusStyle;

  /// Minimum zoom supported by the tile provider.
  ///
  /// This is a tile-source capability, not an interaction limit. The map is
  /// static, but this value still matters because different public tile
  /// providers may refuse requests outside their supported zoom range.
  final int tileMinZoom;

  /// Maximum zoom supported by the tile provider.
  ///
  /// If [zoom] is greater than this value, the widget overzooms locally by
  /// reusing the highest available provider tiles instead of requesting tiles
  /// above this level.
  final int tileMaxZoom;

  /// The zoom level to use for the map camera.
  ///
  /// When `null`, the widget automatically chooses a zoom that tries to fit the
  /// full radius circle while respecting [tileMinZoom] and [tileMaxZoom].
  ///
  /// When provided, the widget always starts at this exact zoom level centered
  /// on [location]. If this value is greater than [tileMaxZoom], the widget
  /// overzooms locally by reusing the highest available tile level from the
  /// provider instead of requesting higher zoom tiles from the tile server.
  ///
  /// Overzoom can be useful when the caller wants a tighter framing than the
  /// tile source natively supports, especially for small radiuses. The tradeoff
  /// is that the map will not gain extra real detail past [tileMaxZoom]:
  /// geometry can look softer, linework can appear thicker, and labels may feel
  /// less precise because the widget is stretching lower-zoom tiles rather than
  /// loading higher-zoom data from the server.
  ///
  /// This value must be greater than or equal to [tileMinZoom].
  final double? zoom;

  /// Displacement of the radius circle from the viewport center, in logical
  /// pixels.
  ///
  /// The map camera shifts so that the radius circle (still geographically at
  /// [location]) renders at `center + offset` on screen. This lets callers
  /// frame the map with more visible area on one side without moving the
  /// location anchor itself.
  ///
  /// Defaults to `Offset.zero`, which keeps the radius centered.
  ///
  /// **Sign convention:**
  /// - `Offset.zero` — radius at viewport center (default).
  /// - `+dx` — radius shifts right; more map visible on the left.
  /// - `+dy` — radius shifts down; more map visible on the top.
  /// - `-dy` — radius shifts up; more map visible on the bottom.
  ///
  /// This value is applied once at build time through the
  /// `initialCameraPosition`. Changing it after creation has no effect.
  ///
  /// ```dart
  /// QuiLocationRadiusMap(
  ///   tileUrlTemplate: 'https://tiles.example.com/{z}/{x}/{y}.mvt',
  ///   location: (latitude: -23.55052, longitude: -46.633308),
  ///   fontConfig: (
  ///     fontStack: 'Inter Regular',
  ///     glyphUrlTemplate: 'https://example.com/glyphs/{fontstack}/{range}.pbf',
  ///   ),
  ///   radiusInMeters: 500,
  ///   offset: Offset(0, -40),
  /// )
  /// ```
  final Offset offset;

  /// Font stack and glyphs URL for text labels on the map.
  final ({String fontStack, String glyphUrlTemplate}) fontConfig;

  @override
  State<QuiLocationRadiusMap> createState() => _QuiLocationRadiusMapState();
}

class _QuiLocationRadiusMapState extends State<QuiLocationRadiusMap> with SingleTickerProviderStateMixin {
  late final String _styleJson = jsonEncode(
    QuiMapLibreStyle.light(
      tileUrlTemplate: widget.tileUrlTemplate,
      fontConfig: widget.fontConfig,
      tileMinZoom: widget.tileMinZoom,
      tileMaxZoom: widget.tileMaxZoom,
    ),
  );

  late final AnimationController _animController;
  MapLibreMapController? _mapController;
  Circle? _radiusCircle;
  double? _computedZoom;
  double _mapOpacity = 0;
  double _targetPixelRadius = 0;
  bool _hasSetUpRadius = false;
  Timer? _wobbleTimer;
  late LatLng _wobbleFromLatLng;
  late LatLng _wobbleToLatLng;
  double _wobbleFromRadius = 1;
  double _wobbleToRadius = 1;
  double? _pendingSettleZoom;

  double get _effectiveMaxZoom => math.max(widget.zoom ?? widget.tileMaxZoom.toDouble(), widget.tileMaxZoom.toDouble());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400))
      ..addListener(_onAnimationTick);
  }

  double _computeZoomForRadius(Size viewport) {
    const earthCircumference = 40075016.686;
    const tileSize = 256.0;
    const padding = 36.0;

    final centerToEdge = math.max(widget.radiusInMeters / 2, QuiLocationRadiusMap._minimumFitRadiusInMeters / 2);
    final usablePixels = math.min(viewport.width, viewport.height) - padding * 2;

    if (usablePixels <= 0) return widget.tileMinZoom.toDouble();

    final latRad = widget.location.latitude * math.pi / 180;
    final cosLat = math.max(math.cos(latRad).abs(), 0.01);

    final twoToZoom = usablePixels * earthCircumference / (2 * centerToEdge * tileSize * cosLat);
    final zoom = math.log(twoToZoom) / math.ln2;

    return zoom.clamp(widget.tileMinZoom.toDouble(), _effectiveMaxZoom);
  }

  double _metersToPixels(double meters, double zoom, double latitude) {
    const earthCircumference = 40075016.686;
    final latRad = latitude * math.pi / 180;
    final metersPerPixel = earthCircumference * math.cos(latRad).abs() / (256 * math.pow(2, zoom));
    return meters / metersPerPixel;
  }

  LatLng _cameraTargetForOffset(double zoom) {
    final offset = widget.offset;
    if (offset == Offset.zero) return LatLng(widget.location.latitude, widget.location.longitude);

    const tileSize = 256.0;
    final latRad = widget.location.latitude * math.pi / 180;
    final cosLat = math.max(math.cos(latRad).abs(), 0.01);
    final degreesPerPixel = 360.0 / (tileSize * math.pow(2, zoom));
    return LatLng(
      widget.location.latitude + offset.dy * degreesPerPixel * cosLat,
      widget.location.longitude - offset.dx * degreesPerPixel,
    );
  }

  // Required callback signature; cannot be a setter.
  // ignore: use_setters_to_change_properties
  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    setState(() => _mapOpacity = 1);
    if (_radiusCircle != null) return;
    _createAndStartWobble();
  }

  void _onAnimationTick() {
    final circle = _radiusCircle;
    final controller = _mapController;
    if (circle == null || controller == null) return;

    final t = Curves.easeOutCubic.transform(_animController.value);
    final lat = _wobbleFromLatLng.latitude + (_wobbleToLatLng.latitude - _wobbleFromLatLng.latitude) * t;
    final lng = _wobbleFromLatLng.longitude + (_wobbleToLatLng.longitude - _wobbleFromLatLng.longitude) * t;
    final radius = _wobbleFromRadius + (_wobbleToRadius - _wobbleFromRadius) * t;

    controller.updateCircle(circle, CircleOptions(geometry: LatLng(lat, lng), circleRadius: radius < 1 ? 1 : radius));
  }

  Future<void> _createAndStartWobble() async {
    final controller = _mapController;
    if (controller == null) return;

    final rng = math.Random();
    final latOffset = (rng.nextDouble() - 0.5) * 0.008;
    final lngOffset = (rng.nextDouble() - 0.5) * 0.008;
    final randomLat = widget.location.latitude + latOffset;
    final randomLng = widget.location.longitude + lngOffset;
    final randomRadius = rng.nextDouble() * 40 + 20;

    final primaryColor = context.qui.colors.primary;
    final style = widget.radiusStyle;
    final fillColor = style.color ?? primaryColor.withValues(alpha: 0.15);
    final borderColor = style.borderColor ?? primaryColor.withValues(alpha: 0.4);

    _radiusCircle = await controller.addCircle(
      CircleOptions(
        geometry: LatLng(randomLat, randomLng),
        circleRadius: randomRadius,
        circleColor: fillColor.toHex(),
        circleOpacity: fillColor.a,
        circleStrokeWidth: style.borderWidth,
        circleStrokeColor: borderColor.toHex(),
        circleStrokeOpacity: style.borderWidth > 0 ? borderColor.a : 0,
      ),
    );

    _wobbleFromLatLng = LatLng(randomLat, randomLng);
    _wobbleToLatLng = LatLng(randomLat, randomLng);
    _wobbleFromRadius = randomRadius;
    _wobbleToRadius = randomRadius;

    _wobbleTimer = Timer.periodic(const Duration(milliseconds: 600), (_) {
      if (_pendingSettleZoom != null) {
        _wobbleTimer?.cancel();
        _wobbleTimer = null;
        _settleCircleToTarget(_pendingSettleZoom!);
        _pendingSettleZoom = null;
        return;
      }

      _wobbleFromLatLng = _wobbleToLatLng;
      _wobbleFromRadius = _wobbleToRadius;
      _wobbleToLatLng = LatLng(
        widget.location.latitude + (rng.nextDouble() - 0.5) * 0.008,
        widget.location.longitude + (rng.nextDouble() - 0.5) * 0.008,
      );
      _wobbleToRadius = rng.nextDouble() * 40 + 20;
      _animController.forward(from: 0);
    });

    unawaited(_animController.forward(from: 0));
  }

  void _settleCircleToTarget(double zoom) {
    final controller = _mapController;
    if (controller == null) return;

    final centerToEdge = widget.radiusInMeters / 2;
    _targetPixelRadius = _metersToPixels(centerToEdge, zoom, widget.location.latitude);
    if (_targetPixelRadius < 1) _targetPixelRadius = 1;

    final t = Curves.easeOutCubic.transform(_animController.value);
    final currentLat = _wobbleFromLatLng.latitude + (_wobbleToLatLng.latitude - _wobbleFromLatLng.latitude) * t;
    final currentLng = _wobbleFromLatLng.longitude + (_wobbleToLatLng.longitude - _wobbleFromLatLng.longitude) * t;
    final currentRadius = _wobbleFromRadius + (_wobbleToRadius - _wobbleFromRadius) * t;

    _wobbleFromLatLng = LatLng(currentLat, currentLng);
    _wobbleFromRadius = currentRadius;
    _wobbleToLatLng = LatLng(widget.location.latitude, widget.location.longitude);
    _wobbleToRadius = _targetPixelRadius;

    _animController.forward(from: 0);
  }

  @override
  void dispose() {
    _wobbleTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _computedZoom ??= _computeZoomForRadius(Size(constraints.maxWidth, constraints.maxHeight));

        return AnimatedOpacity(
          opacity: _mapOpacity,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
          child: MapLibreMap(
            initialCameraPosition: CameraPosition(
              target: _cameraTargetForOffset(widget.zoom ?? _computedZoom!),
              zoom: widget.zoom ?? _computedZoom!,
            ),
            styleString: _styleJson,
            attributionButtonMargins: const math.Point(-50, -50),
            attributionButtonPosition: AttributionButtonPosition.topRight,
            onMapCreated: _onMapCreated,
            onStyleLoadedCallback: _onStyleLoaded,
            onMapIdle: () {
              if (_hasSetUpRadius) return;
              _hasSetUpRadius = true;
              _pendingSettleZoom = widget.zoom ?? _computedZoom;
            },
            dragEnabled: false,
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: false,
            zoomGesturesEnabled: false,
            tiltGesturesEnabled: false,
            doubleClickZoomEnabled: false,
            compassEnabled: false,
            logoEnabled: false,
            minMaxZoomPreference: MinMaxZoomPreference(widget.tileMinZoom.toDouble(), _effectiveMaxZoom),
          ),
        );
      },
    );
  }
}

@Preview(name: 'QuiLocationRadiusMap', group: 'Maps')
Widget quiLocationRadiusMapPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: QuiLocationRadiusMap(
              tileUrlTemplate: 'https://tiles.example.com/openmaptiles/{z}/{x}/{y}.mvt',
              location: const (latitude: -23.55052, longitude: -46.633308),
              fontConfig: (
                fontStack: 'Inter Regular',
                glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf',
              ),
              radiusInMeters: 500,
            ),
          ),
        ),
      ),
    ),
  );
}

@Preview(name: 'QuiLocationRadiusMap with offset', group: 'Maps')
Widget quiLocationRadiusMapWithOffsetPreview() {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: QuiTheme.light(primaryColor: const Color(0xFFFF4A4B)),
    home: Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: QuiLocationRadiusMap(
              tileUrlTemplate: 'https://tiles.example.com/openmaptiles/{z}/{x}/{y}.mvt',
              location: const (latitude: -23.55052, longitude: -46.633308),
              fontConfig: (
                fontStack: 'Inter Regular',
                glyphUrlTemplate: 'file://packages/qui/assets/glyphs/{fontstack}/{range}.pbf',
              ),
              radiusInMeters: 500,
              offset: const Offset(0, -40),
            ),
          ),
        ),
      ),
    ),
  );
}
