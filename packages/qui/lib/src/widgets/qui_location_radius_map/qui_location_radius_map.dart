import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
import 'package:qui/src/theme/map_style/qui_map_style.dart';
import 'package:qui/src/theme/qui_color_scheme/qui_color_scheme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';

part 'qui_location_radius_map_radius_painter.dart';

/// Non-interactive vector map that highlights an approximate location radius.
///
/// `QuiLocationRadiusMap` is designed for location disclosure
/// experiences where the app should show the general area of a post, host, or
/// opportunity without exposing an exact pin. The map is intentionally
/// non-interactive: users cannot pan, zoom, rotate, or pinch it.
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
    this.radiusStyle = const (color: null),
    this.tileMinZoom = 1,
    this.tileMaxZoom = 14,
    this.zoom,
    this.offset = Offset.zero,
    this.maximumMapFps = 30,
    this.onMapLoad,
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
       assert(offset.isFinite, 'offset must be finite and not NaN'),
       assert(maximumMapFps > 0 && maximumMapFps <= 60, 'maximumMapFps must be between 1 and 60.');

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
  final ({Color? color}) radiusStyle;

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

  /// Maximum frame rate used by the native map rendering.
  ///
  /// Defaults to 30 FPS to reduce GPU work on low-end devices.
  final int maximumMapFps;

  /// Called once when the map has finished loading — style parsed, tiles
  /// fetched, and first frame composited.
  final VoidCallback? onMapLoad;

  @override
  State<QuiLocationRadiusMap> createState() => _QuiLocationRadiusMapState();
}

class _QuiLocationRadiusMapState extends State<QuiLocationRadiusMap> with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  late String _styleJson;
  late LatLng _wobbleFromLatLng;
  late LatLng _wobbleToLatLng;
  QuiMapColorScheme? _mapColorScheme;
  double? _computedZoom;
  double? _pendingSettleZoom;
  Completer<void>? _mapIdleCompleter;
  Timer? _wobbleTimer;

  double _overlayOpacity = 0;
  double _targetPixelRadius = 0;
  bool _hasSetUpRadius = false;
  bool _hasStartedWobble = false;
  int _mapGeneration = 0;
  double _wobbleFromRadius = 1;
  double _wobbleToRadius = 1;

  double get _effectiveMaxZoom => math.max(widget.zoom ?? widget.tileMaxZoom.toDouble(), widget.tileMaxZoom.toDouble());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final mapColorScheme = context.qui.colorScheme.map;
    final oldMapColorScheme = _mapColorScheme;

    _mapColorScheme = mapColorScheme;
    _styleJson = _buildStyleJson(mapColorScheme);

    if (oldMapColorScheme != null && oldMapColorScheme != mapColorScheme) {
      _resetMapConfiguration();
    }
  }

  @override
  void didUpdateWidget(covariant QuiLocationRadiusMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_hasMapConfigurationChanged(oldWidget)) {
      _resetMapConfiguration();
    }
  }

  String _buildStyleJson(QuiMapColorScheme mapColorScheme) {
    return jsonEncode(
      QuiMapLibreStyle.light(
        tileUrlTemplate: widget.tileUrlTemplate,
        fontConfig: widget.fontConfig,
        colorScheme: mapColorScheme,
        tileMinZoom: widget.tileMinZoom,
        tileMaxZoom: widget.tileMaxZoom,
      ),
    );
  }

  bool _hasMapConfigurationChanged(QuiLocationRadiusMap oldWidget) {
    return oldWidget.tileUrlTemplate != widget.tileUrlTemplate ||
        oldWidget.location != widget.location ||
        oldWidget.radiusInMeters != widget.radiusInMeters ||
        oldWidget.radiusStyle != widget.radiusStyle ||
        oldWidget.fontConfig != widget.fontConfig ||
        oldWidget.tileMinZoom != widget.tileMinZoom ||
        oldWidget.tileMaxZoom != widget.tileMaxZoom ||
        oldWidget.zoom != widget.zoom ||
        oldWidget.offset != widget.offset ||
        oldWidget.maximumMapFps != widget.maximumMapFps;
  }

  void _resetMapConfiguration() {
    _mapGeneration += 1;
    _styleJson = _buildStyleJson(_mapColorScheme ?? context.qui.colorScheme.map);
    _computedZoom = null;
    _mapIdleCompleter?.complete();
    _mapIdleCompleter = null;
    _overlayOpacity = 0;
    _hasSetUpRadius = false;
    _pendingSettleZoom = null;
    _wobbleTimer?.cancel();
    _wobbleTimer = null;
    _hasStartedWobble = false;
    _animController.stop();
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

  void _onMapCreated(MapLibreMapController controller) {
    unawaited(_limitNativeMapFrameRate(controller));
  }

  Future<void> _limitNativeMapFrameRate(MapLibreMapController controller) async {
    try {
      await controller.setMaximumFps(widget.maximumMapFps);
    } catch (_) {
      // FPS control is a best-effort optimization.
    }
  }

  void _onStyleLoaded() {
    if (mounted) setState(() => _overlayOpacity = 1);
    _createAndStartWobble();
  }

  void _createAndStartWobble() {
    if (_hasStartedWobble) return;

    final rng = math.Random();
    final latOffset = (rng.nextDouble() - 0.5) * 0.008;
    final lngOffset = (rng.nextDouble() - 0.5) * 0.008;
    final randomLat = widget.location.latitude + latOffset;
    final randomLng = widget.location.longitude + lngOffset;
    final randomRadius = rng.nextDouble() * 40 + 20;

    _wobbleFromLatLng = LatLng(randomLat, randomLng);
    _wobbleToLatLng = LatLng(randomLat, randomLng);
    _wobbleFromRadius = randomRadius;
    _wobbleToRadius = randomRadius;
    _hasStartedWobble = true;

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

  void _onMapIdle() {
    final mapIdleCompleter = _mapIdleCompleter;
    if (mapIdleCompleter != null && !mapIdleCompleter.isCompleted) {
      mapIdleCompleter.complete();
    }

    if (_hasSetUpRadius) return;

    _hasSetUpRadius = true;
    _pendingSettleZoom = widget.zoom ?? _computedZoom;
    widget.onMapLoad?.call();
  }

  _QuiLocationRadiusMapRadiusFrame _radiusFrame() {
    final style = widget.radiusStyle;
    final effectiveZoom = widget.zoom ?? _computedZoom ?? widget.tileMinZoom.toDouble();

    return _QuiLocationRadiusMapRadiusFrame(
      isVisible: _hasStartedWobble,
      animationValue: _animController.value,
      fromLocation: (
        latitude: _hasStartedWobble ? _wobbleFromLatLng.latitude : widget.location.latitude,
        longitude: _hasStartedWobble ? _wobbleFromLatLng.longitude : widget.location.longitude,
      ),
      toLocation: (
        latitude: _hasStartedWobble ? _wobbleToLatLng.latitude : widget.location.latitude,
        longitude: _hasStartedWobble ? _wobbleToLatLng.longitude : widget.location.longitude,
      ),
      fromRadius: _wobbleFromRadius,
      toRadius: _wobbleToRadius,
      cameraTarget: _cameraTargetForOffset(effectiveZoom),
      zoom: effectiveZoom,
      fillColor: style.color ?? context.qui.colorScheme.map.locationRadius,
    );
  }

  Widget _buildNativeMap({required double zoom, required Object mapKey}) {
    return ColoredBox(
      color: context.qui.colorScheme.map.background,
      child: MapLibreMap(
        key: ValueKey<Object>(mapKey),
        foregroundLoadColor: context.qui.colorScheme.map.background,
        translucentTextureSurface: true,
        initialCameraPosition: CameraPosition(target: _cameraTargetForOffset(zoom), zoom: zoom),
        styleString: _styleJson,
        attributionButtonMargins: const math.Point(-50, -50),
        attributionButtonPosition: AttributionButtonPosition.topRight,
        onMapCreated: _onMapCreated,
        onStyleLoadedCallback: _onStyleLoaded,
        onMapIdle: _onMapIdle,
        annotationOrder: const <AnnotationType>[],
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
  }

  @override
  void dispose() {
    _mapGeneration += 1;
    _wobbleTimer?.cancel();
    final mapIdleCompleter = _mapIdleCompleter;
    if (mapIdleCompleter != null && !mapIdleCompleter.isCompleted) {
      mapIdleCompleter.complete();
    }
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final viewport = Size(constraints.maxWidth, constraints.maxHeight);
        _computedZoom ??= _computeZoomForRadius(viewport);
        final effectiveZoom = widget.zoom ?? _computedZoom!;

        return Stack(
          fit: StackFit.expand,
          children: [
            _buildNativeMap(zoom: effectiveZoom, mapKey: 'map_$_mapGeneration'),
            AnimatedOpacity(
              opacity: _overlayOpacity,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _QuiLocationRadiusMapRadiusPainter(
                    animation: _animController,
                    curve: Curves.easeOutCubic,
                    frameProvider: _radiusFrame,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
