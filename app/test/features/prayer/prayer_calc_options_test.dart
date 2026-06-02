import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/prayer/domain/prayer_calc_options.dart';

void main() {
  group('PrayerCalcOptions', () {
    test('method ids exactly match PrayerService-supported ids and are unique', () {
      final ids = kPrayerMethods.map((m) => m.id).toList();
      expect(ids.toSet().length, ids.length); // unique
      expect(ids, containsAll(<String>[
        'ummAlQura', 'muslimWorldLeague', 'egyptian', 'karachi',
        'dubai', 'qatar', 'kuwait', 'northAmerica', 'turkey',
      ]));
      // Umm al-Qura is first (the Tarf/KSA default).
      expect(kPrayerMethods.first.id, 'ummAlQura');
    });

    test('every method/madhab option exposes a non-empty l10n key', () {
      for (final m in kPrayerMethods) {
        expect(m.l10nKey, isNotEmpty);
      }
      for (final m in kMadhabs) {
        expect(m.l10nKey, isNotEmpty);
      }
      expect(kMadhabs.map((m) => m.id).toList(), <String>['shafi', 'hanafi']);
    });
  });
}
