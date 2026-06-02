import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A latitude/longitude pair.
@immutable
class GeoFix {
  const GeoFix(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Optional device geolocation behind a seam so the picker is manual-first and
/// fully testable. Implementations MUST be honest: if unsupported or permission
/// is denied, return null (never throw) so the UI falls back to manual entry.
abstract interface class GeoLocator {
  bool get isSupported;

  /// The current device location, or null if unavailable/denied. Never throws.
  Future<GeoFix?> currentLatLng();
}

/// Default: geolocation not wired (no plugin/permission). Keeps Tarf shipping
/// and offline-first; the picker stays on manual entry.
class UnavailableGeoLocator implements GeoLocator {
  const UnavailableGeoLocator();
  @override
  bool get isSupported => false;
  @override
  Future<GeoFix?> currentLatLng() async => null;
}

/// Records calls / yields a seeded fix for tests.
class FakeGeoLocator implements GeoLocator {
  FakeGeoLocator(this._fix, {this.supported = true});
  final GeoFix? _fix;
  final bool supported;
  int calls = 0;
  @override
  bool get isSupported => supported;
  @override
  Future<GeoFix?> currentLatLng() async {
    calls++;
    return _fix;
  }
}

/// Defaults to manual-first ([UnavailableGeoLocator]): the picker fully works on
/// lat/lng/city entry alone, and no native location-permission surface ships.
/// Device geolocation is a FUTURE DELIBERATE OPT-IN — adding it means re-adding
/// the `geolocator` dependency, a real GeoLocator impl, and the platform
/// permission strings together, then overriding this provider in a bootstrap.
final geoLocatorProvider =
    Provider<GeoLocator>((ref) => const UnavailableGeoLocator());
