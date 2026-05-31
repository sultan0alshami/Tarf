import 'package:adhan/adhan.dart';

/// Computes the five daily prayer times and whether a given moment falls within
/// a pause window just after one of them — so eye-break reminders can defer
/// around salah. Location/method/madhab come from the user's eye-care config.
abstract final class PrayerService {
  PrayerService._();

  static CalculationParameters _params(String method, String madhab) {
    final m = switch (method) {
      'muslimWorldLeague' => CalculationMethod.muslim_world_league,
      'egyptian' => CalculationMethod.egyptian,
      'karachi' => CalculationMethod.karachi,
      'ummAlQura' => CalculationMethod.umm_al_qura,
      'dubai' => CalculationMethod.dubai,
      'qatar' => CalculationMethod.qatar,
      'kuwait' => CalculationMethod.kuwait,
      'northAmerica' => CalculationMethod.north_america,
      'turkey' => CalculationMethod.turkey,
      _ => CalculationMethod.umm_al_qura,
    };
    final p = m.getParameters();
    p.madhab = madhab == 'hanafi' ? Madhab.hanafi : Madhab.shafi;
    return p;
  }

  /// The five obligatory prayer times for [day]'s local date, in local time.
  static List<DateTime> timesFor({
    required double latitude,
    required double longitude,
    required DateTime day,
    required String method,
    required String madhab,
  }) {
    final pt = PrayerTimes(
      Coordinates(latitude, longitude),
      DateComponents.from(day),
      _params(method, madhab),
      utcOffset: day.timeZoneOffset,
    );
    return [pt.fajr, pt.dhuhr, pt.asr, pt.maghrib, pt.isha];
  }

  /// True if [now] is within [window] starting at any prayer time, i.e. in the
  /// interval [prayer, prayer + window).
  static bool inWindow({
    required double latitude,
    required double longitude,
    required DateTime now,
    required Duration window,
    required String method,
    required String madhab,
  }) {
    final times = timesFor(
      latitude: latitude,
      longitude: longitude,
      day: now,
      method: method,
      madhab: madhab,
    );
    for (final t in times) {
      if (!now.isBefore(t) && now.isBefore(t.add(window))) return true;
    }
    return false;
  }
}
