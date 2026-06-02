import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/prayer/application/geo_locator.dart';

void main() {
  test('UnavailableGeoLocator reports unsupported and returns null', () async {
    const g = UnavailableGeoLocator();
    expect(g.isSupported, isFalse);
    expect(await g.currentLatLng(), isNull);
  });

  test('FakeGeoLocator yields the seeded fix', () async {
    final g = FakeGeoLocator(const GeoFix(21.4225, 39.8262));
    expect(g.isSupported, isTrue);
    expect((await g.currentLatLng())!.latitude, 21.4225);
  });

  test('default provider is the Unavailable locator (manual-first)', () {
    final c = ProviderContainer();
    addTearDown(c.dispose);
    expect(c.read(geoLocatorProvider), isA<UnavailableGeoLocator>());
  });
}
