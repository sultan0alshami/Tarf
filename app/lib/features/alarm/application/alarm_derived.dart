import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../eyecare/application/eyecare_config_controller.dart';
import '../../eyecare/core/prayer_service.dart';
import '../domain/alarm_item.dart';
import 'alarms_controller.dart';

/// A computed prayer "alarm": the prayer [id] (fajr…isha), its [time] today, and
/// whether it is enabled to ring.
class PrayerAlarm {
  const PrayerAlarm({
    required this.id,
    required this.time,
    required this.enabled,
  });

  final String id;
  final DateTime time;
  final bool enabled;
}

const prayerIds = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

/// The five daily prayers as derived alarms — times from [PrayerService] using
/// the eye-care location/method, enable flags from `EyeCareConfig`. Recomputed
/// whenever the config changes (and on rebuild, for today's date).
final prayerAlarmsProvider = Provider<List<PrayerAlarm>>((ref) {
  final cfg = ref.watch(eyeCareConfigProvider);
  final times = PrayerService.timesFor(
    latitude: cfg.prayerLatitude,
    longitude: cfg.prayerLongitude,
    day: DateTime.now(),
    method: cfg.prayerMethod,
    madhab: cfg.prayerMadhab,
  );
  return [
    for (var i = 0; i < prayerIds.length && i < times.length; i++)
      PrayerAlarm(
        id: prayerIds[i],
        time: times[i],
        enabled: cfg.prayerAlarmsEnabled.contains(prayerIds[i]),
      ),
  ];
});

/// Duration until the soonest upcoming enabled alarm (standard or prayer), or
/// null if none. Drives the "Ring in HH:MM" readout. Computed on watch.
final nextAlarmProvider = Provider<Duration?>((ref) {
  final now = DateTime.now();
  final alarms = ref.watch(alarmsControllerProvider);
  final prayers = ref.watch(prayerAlarmsProvider);

  DateTime? soonest;
  void consider(DateTime t) {
    if (t.isAfter(now) && (soonest == null || t.isBefore(soonest!))) {
      soonest = t;
    }
  }

  for (final a in alarms) {
    if (a.enabled) consider(_nextOccurrence(a, now));
  }
  for (final p in prayers) {
    if (p.enabled && p.time.isAfter(now)) consider(p.time);
  }
  return soonest?.difference(now);
});

/// The next time [a] will fire on or after [now], honoring its repeat [days]
/// (empty days = one-shot → the next future occurrence of that clock time).
DateTime _nextOccurrence(AlarmItem a, DateTime now) {
  for (var add = 0; add <= 7; add++) {
    final d = DateTime(now.year, now.month, now.day, a.hour, a.minute)
        .add(Duration(days: add));
    if (!d.isAfter(now)) continue;
    if (a.days.isEmpty || a.days.contains(d.weekday)) return d;
  }
  return DateTime(now.year, now.month, now.day, a.hour, a.minute)
      .add(const Duration(days: 1));
}
