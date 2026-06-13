import 'dart:convert';
import 'dart:math' as math;

import 'package:cataqui_core/cataqui_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import 'package:maplibre_gl/maplibre_gl.dart';
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
  }) : assert(location.latitude >= -90 && location.latitude <= 90, 'location.latitude must be between -90 and 90'),
       assert(
         location.longitude >= -180 && location.longitude <= 180,
         'location.longitude must be between -180 and 180',
       ),
       assert(radiusInMeters >= 0, 'radiusInMeters must be greater than or equal to zero'),
       assert(tileMinZoom >= 0, 'tileMinZoom must be greater than or equal to zero'),
       assert(tileMaxZoom > 0, 'tileMaxZoom must be greater than zero'),
       assert(tileMinZoom <= tileMaxZoom, 'tileMinZoom must be less than or equal to tileMaxZoom'),
       assert(zoom == null || zoom >= tileMinZoom, 'zoom must be greater than or equal to tileMinZoom');

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
  double _targetFillOpacity = 0;
  double _targetStrokeOpacity = 0;

  double get _effectiveMaxZoom => math.max(widget.zoom ?? widget.tileMaxZoom.toDouble(), widget.tileMaxZoom.toDouble());

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
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

  // Required callback signature; cannot be a setter.
  // ignore: use_setters_to_change_properties
  void _onMapCreated(MapLibreMapController controller) {
    _mapController = controller;
  }

  void _onStyleLoaded() {
    final zoom = widget.zoom ?? _computedZoom;
    if (zoom == null) return;
    setState(() => _mapOpacity = 1);
    _setupRadiusCircle(zoom);
  }

  void _onAnimationTick() {
    final circle = _radiusCircle;
    final controller = _mapController;
    if (circle == null || controller == null) return;

    final t = Curves.easeOutCubic.transform(_animController.value);
    final radius = 1 + (_targetPixelRadius - 1) * t;
    final opacity = _targetFillOpacity * t;
    final strokeOpacity = _targetStrokeOpacity * t;

    controller.updateCircle(
      circle,
      CircleOptions(circleRadius: radius < 1 ? 1 : radius, circleOpacity: opacity, circleStrokeOpacity: strokeOpacity),
    );
  }

  Future<void> _setupRadiusCircle(double zoom) async {
    final controller = _mapController;
    if (controller == null) return;

    final centerToEdge = widget.radiusInMeters / 2;
    _targetPixelRadius = _metersToPixels(centerToEdge, zoom, widget.location.latitude);
    if (_targetPixelRadius < 1) _targetPixelRadius = 1;

    final primaryColor = context.qui.colors.primary;
    final style = widget.radiusStyle;
    final fillColor = style.color ?? primaryColor.withValues(alpha: 0.15);
    final borderColor = style.borderColor ?? primaryColor.withValues(alpha: 0.4);
    _targetFillOpacity = fillColor.a;
    _targetStrokeOpacity = style.borderWidth > 0 ? borderColor.a : 0;

    _radiusCircle = await controller.addCircle(
      CircleOptions(
        geometry: LatLng(widget.location.latitude, widget.location.longitude),
        circleRadius: 1,
        circleColor: fillColor.toHex(),
        circleOpacity: 0,
        circleStrokeWidth: style.borderWidth,
        circleStrokeColor: borderColor.toHex(),
        circleStrokeOpacity: 0,
      ),
    );

    await _animController.forward(from: 0);
  }

  @override
  void dispose() {
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
                target: LatLng(widget.location.latitude, widget.location.longitude),
                zoom: widget.zoom ?? _computedZoom!,
              ),
              styleString: _styleJson,
              attributionButtonMargins: const math.Point(-50, -50),
              attributionButtonPosition: AttributionButtonPosition.topRight,
              onMapCreated: _onMapCreated,
              onStyleLoadedCallback: _onStyleLoaded,
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
