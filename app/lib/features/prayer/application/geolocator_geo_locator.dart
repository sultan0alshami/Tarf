import 'package:geolocator/geolocator.dart';

import 'geo_locator.dart';

/// Real device geolocation. Requests permission, honors denial silently, and
/// returns null on any failure so the picker never shows an error wall.
class GeolocatorGeoLocator implements GeoLocator {
  const GeolocatorGeoLocator();

  @override
  bool get isSupported => true;

  @override
  Future<GeoFix?> currentLatLng() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        return null;
      }
      final pos = await Geolocator.getCurrentPosition();
      return GeoFix(pos.latitude, pos.longitude);
    } catch (_) {
      return null;
    }
  }
}
