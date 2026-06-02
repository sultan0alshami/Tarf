import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';

void main() {
  test('prayerCityLabel defaults empty and round-trips through json', () {
    const cfg = EyeCareConfig();
    expect(cfg.prayerCityLabel, '');
    final next = cfg.copyWith(
      prayerCityLabel: 'Makkah',
      prayerLatitude: 21.4225,
      prayerLongitude: 39.8262,
      prayerMethod: 'muslimWorldLeague',
      prayerMadhab: 'hanafi',
    );
    final round = EyeCareConfig.fromJson(next.toJson());
    expect(round.prayerCityLabel, 'Makkah');
    expect(round.prayerLatitude, 21.4225);
    expect(round.prayerMethod, 'muslimWorldLeague');
    expect(round.prayerMadhab, 'hanafi');
  });

  test('legacy json without prayerCity decodes to empty label', () {
    final legacy = const EyeCareConfig().toJson()..remove('prayerCity');
    expect(EyeCareConfig.fromJson(legacy).prayerCityLabel, '');
  });
}
