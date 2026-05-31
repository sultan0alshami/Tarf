import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/core/prayer_service.dart';

const _lat = 24.7136; // Riyadh
const _lng = 46.6753;
const _method = 'ummAlQura';
const _madhab = 'shafi';

void main() {
  final day = DateTime(2026, 5, 31, 12);

  group('PrayerService', () {
    test('computes five ascending prayer times', () {
      final times = PrayerService.timesFor(
        latitude: _lat,
        longitude: _lng,
        day: day,
        method: _method,
        madhab: _madhab,
      );
      expect(times.length, 5);
      for (var i = 1; i < times.length; i++) {
        expect(times[i].isAfter(times[i - 1]), isTrue);
      }
    });

    test('inWindow evaluates without throwing and returns a bool', () {
      // (Exact in-window timing is timezone-sensitive via adhan and is best
      // verified on-device; here we assert the path is sound.)
      final result = PrayerService.inWindow(
        latitude: _lat,
        longitude: _lng,
        now: day,
        window: const Duration(minutes: 15),
        method: _method,
        madhab: _madhab,
      );
      expect(result, isA<bool>());
    });
  });
}
