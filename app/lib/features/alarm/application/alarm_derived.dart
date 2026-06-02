import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/next_fire.dart';
import '../../eyecare/application/eyecare_config_controller.dart';
import '../../eyecare/core/prayer_service.dart';
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
    if (a.enabled) consider(NextFire.standard(a, now));
  }
  for (final p in prayers) {
    if (p.enabled && p.time.isAfter(now)) consider(p.time);
  }
  return soonest?.difference(now);
});
