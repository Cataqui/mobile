import 'dart:math' as math;

import 'package:cataqui_app/widgets/job_location_map/job_location_map_color_scheme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mateo_mobile/mateo_mobile.dart';

/// Displays a passive Google map with an approximate job-location area.
///
/// The map follows the active Mateo map color scheme and is configured for
/// lightweight, non-interactive rendering inside scrolling feed cards.
class JobLocationMap extends StatelessWidget {
  /// Creates a map centered around [location].
  ///
  /// [areaDiameterInMeters] is the full width of the approximate location
  /// area, matching the feed API's existing radius-field display contract.
  JobLocationMap({
    required this.location,
    required this.areaDiameterInMeters,
    super.key,
    this.zoom = 13.5,
    this.offset = Offset.zero,
  }) : assert(location.latitude >= -90 && location.latitude <= 90, 'location.latitude must be between -90 and 90'),
       assert(
         location.longitude >= -180 && location.longitude <= 180,
         'location.longitude must be between -180 and 180',
       ),
       assert(areaDiameterInMeters >= 0, 'areaDiameterInMeters must be greater than or equal to zero'),
       assert(zoom >= 0, 'zoom must be greater than or equal to zero'),
       assert(offset.isFinite, 'offset must be finite and not NaN');

  static const _circleId = CircleId('job-location-area');
  static const _tileSize = 256.0;

  /// Insets that keep Google attribution clear of overlapping feed content.
  static const mapPadding = EdgeInsets.only(bottom: 100);

  /// The approximate job location rendered by the map.
  final ({double latitude, double longitude}) location;

  /// The full diameter, in meters, of the approximate location area.
  final double areaDiameterInMeters;

  /// The fixed Google Maps camera zoom level.
  final double zoom;

  /// The screen-space displacement of the location area from map center.
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = JobLocationMapColorScheme.fromBrightness(
      brightness: Theme.of(context).brightness,
      palette: context.mateo.palette,
    );
    final mapKey = (location, areaDiameterInMeters, zoom, offset, mapPadding);

    return ColoredBox(
      color: colorScheme.background,
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: GoogleMap(
            key: ValueKey<Object>(mapKey),
            initialCameraPosition: CameraPosition(target: _cameraTarget(), zoom: zoom),
            backgroundColor: colorScheme.background,
            mapType: MapType.normal,
            minMaxZoomPreference: MinMaxZoomPreference(zoom, zoom),
            padding: mapPadding,
            liteModeEnabled: defaultTargetPlatform == TargetPlatform.android,
            compassEnabled: false,
            mapToolbarEnabled: false,
            mapTypeControlEnabled: false,
            fullscreenControlEnabled: false,
            streetViewControlEnabled: false,
            rotateGesturesEnabled: false,
            scrollGesturesEnabled: false,
            zoomControlsEnabled: false,
            zoomGesturesEnabled: false,
            tiltGesturesEnabled: false,
            fortyFiveDegreeImageryEnabled: false,
            myLocationEnabled: false,
            myLocationButtonEnabled: false,
            indoorViewEnabled: false,
            trafficEnabled: false,
            buildingsEnabled: false,
            circles: areaDiameterInMeters == 0
                ? const <Circle>{}
                : <Circle>{
                    Circle(
                      circleId: _circleId,
                      center: LatLng(location.latitude, location.longitude),
                      radius: areaDiameterInMeters / 2,
                      fillColor: colorScheme.locationRadius,
                      strokeColor: colorScheme.locationRadius.withValues(alpha: 0),
                      strokeWidth: 0,
                    ),
                  },
          ),
        ),
      ),
    );
  }

  Offset _effectiveOffset() {
    final paddingCenterOffset = Offset(
      (mapPadding.left - mapPadding.right) / 2,
      (mapPadding.top - mapPadding.bottom) / 2,
    );
    return offset - paddingCenterOffset;
  }

  LatLng _cameraTarget() {
    final offset = _effectiveOffset();

    if (offset == Offset.zero) return LatLng(location.latitude, location.longitude);

    final latitudeRadians = location.latitude * math.pi / 180;
    final latitudeScale = math.max(math.cos(latitudeRadians).abs(), 0.01);
    final degreesPerPixel = 360 / (_tileSize * math.pow(2, zoom));

    return LatLng(
      location.latitude + offset.dy * degreesPerPixel * latitudeScale,
      location.longitude - offset.dx * degreesPerPixel,
    );
  }
}
