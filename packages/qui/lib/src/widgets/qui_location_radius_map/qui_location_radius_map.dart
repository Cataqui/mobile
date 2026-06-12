import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Theme;
import 'package:flutter/services.dart';
import 'package:flutter/widget_previews.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:qui/gen/assets.gen.dart';
import 'package:qui/src/theme/qui_theme.dart';
import 'package:qui/src/theme/qui_theme_context.dart';
import 'package:vector_map_tiles/vector_map_tiles.dart';
import 'package:vector_tile_renderer/vector_tile_renderer.dart' as vector_renderer;

part '_qui_map_style.dart';
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
  ///   radiusInMeters: 500,
  /// )
  /// ```
  QuiLocationRadiusMap({
    required this.tileUrlTemplate,
    required this.location,
    required this.radiusInMeters,
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

  static const _openMapTilesSource = 'openmaptiles';
  static const _earthMetersPerDegree = 111320.0;
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

  @override
  State<QuiLocationRadiusMap> createState() => _QuiLocationRadiusMapState();
}

class _QuiLocationRadiusMapState extends State<QuiLocationRadiusMap> {
  late Future<_QuiMapStyle> _styleFuture;

  LatLng get _center => LatLng(widget.location.latitude, widget.location.longitude);

  @override
  void initState() {
    super.initState();
    _styleFuture = _loadStyle();
  }

  @override
  void didUpdateWidget(covariant QuiLocationRadiusMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tileUrlTemplate != widget.tileUrlTemplate ||
        oldWidget.tileMinZoom != widget.tileMinZoom ||
        oldWidget.tileMaxZoom != widget.tileMaxZoom) {
      _styleFuture = _loadStyle();
    }
  }

  @override
  void reassemble() {
    super.reassemble();

    if (kDebugMode) setState(() => _styleFuture = _loadStyle());
  }

  double get _effectiveMaxZoom => math.max(widget.zoom ?? widget.tileMaxZoom.toDouble(), widget.tileMaxZoom.toDouble());

  CameraFit _buildInitialCameraFit() {
    final diameter = math.max(widget.radiusInMeters, QuiLocationRadiusMap._minimumFitRadiusInMeters);
    final halfSpan = diameter / 2;
    final latitudeDelta = halfSpan / QuiLocationRadiusMap._earthMetersPerDegree;
    final latitudeRadians = widget.location.latitude * math.pi / 180;
    final longitudeMetersPerDegree = math.max(
      QuiLocationRadiusMap._earthMetersPerDegree * math.cos(latitudeRadians).abs(),
      1,
    );
    final longitudeDelta = halfSpan / longitudeMetersPerDegree;

    final southWest = LatLng(
      (widget.location.latitude - latitudeDelta).clamp(-90.0, 90.0),
      (widget.location.longitude - longitudeDelta).clamp(-180.0, 180.0),
    );

    final northEast = LatLng(
      (widget.location.latitude + latitudeDelta).clamp(-90.0, 90.0),
      (widget.location.longitude + longitudeDelta).clamp(-180.0, 180.0),
    );

    return CameraFit.bounds(
      bounds: LatLngBounds(southWest, northEast),
      padding: const EdgeInsets.all(36),
      minZoom: widget.tileMinZoom.toDouble(),
      maxZoom: _effectiveMaxZoom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.qui.colors.primary;
    final radiusStyle = widget.radiusStyle;

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: IgnorePointer(
        child: FutureBuilder<_QuiMapStyle>(
          future: _styleFuture,
          builder: (context, snapshot) {
            final mapStyle = snapshot.data;
            if (mapStyle == null) return const ColoredBox(color: Colors.white);

            return FlutterMap(
              options: MapOptions(
                initialCenter: _center,
                initialCameraFit: widget.zoom == null ? _buildInitialCameraFit() : null,
                initialZoom: widget.zoom ?? widget.tileMinZoom.toDouble(),
                minZoom: widget.tileMinZoom.toDouble(),
                maxZoom: _effectiveMaxZoom,
                backgroundColor: context.qui.colors.background,
                interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
              ),
              children: [
                VectorTileLayer(
                  layerMode: VectorTileLayerMode.raster,
                  tileProviders: mapStyle.tileProviders,
                  theme: mapStyle.theme,
                  maximumZoom: _effectiveMaxZoom,
                ),
                CircleLayer(
                  circles: [
                    CircleMarker(
                      point: _center,
                      radius: widget.radiusInMeters / 2,
                      useRadiusInMeter: true,
                      color: radiusStyle.color ?? primaryColor.withValues(alpha: 0.15),
                      borderColor: radiusStyle.borderColor ?? primaryColor.withValues(alpha: 0.4),
                      borderStrokeWidth: radiusStyle.borderWidth,
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<_QuiMapStyle> _loadStyle() async {
    final styleText = await rootBundle.loadString(Assets.maps.quiLightMapStyle, cache: false);
    final decodedStyle = jsonDecode(styleText);

    if (decodedStyle is! Map<String, dynamic>) throw StateError('Qui light map style must be a JSON object.');

    final sources = decodedStyle['sources'];
    if (sources is! Map<String, dynamic>) throw StateError('Qui light map style must define sources.');

    final openMapTilesSource = sources[QuiLocationRadiusMap._openMapTilesSource];
    if (openMapTilesSource is! Map<String, dynamic>) {
      throw StateError('Qui light map style must define the openmaptiles source.');
    }

    openMapTilesSource['tiles'] = <String>[widget.tileUrlTemplate];
    openMapTilesSource['minzoom'] = widget.tileMinZoom;
    openMapTilesSource['maxzoom'] = widget.tileMaxZoom;

    return _QuiMapStyle(
      theme: vector_renderer.ThemeReader().read(decodedStyle),
      tileProviders: TileProviders({
        QuiLocationRadiusMap._openMapTilesSource: NetworkVectorTileProvider(
          urlTemplate: widget.tileUrlTemplate,
          minimumZoom: widget.tileMinZoom,
          maximumZoom: widget.tileMaxZoom,
        ),
      }),
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
              radiusInMeters: 500,
            ),
          ),
        ),
      ),
    ),
  );
}
