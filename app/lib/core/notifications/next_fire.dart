import '../../features/alarm/domain/alarm_item.dart';

/// Pure next-occurrence math for OS scheduling. No platform calls; no DateTime.now.
abstract final class NextFire {
  NextFire._();

  /// The next time [a] fires strictly after [now], honoring repeat days
  /// (empty = one-shot → next future occurrence of the clock time).
  static DateTime standard(AlarmItem a, DateTime now) {
    for (var add = 0; add <= 7; add++) {
      final d = DateTime(now.year, now.month, now.day, a.hour, a.minute)
          .add(Duration(days: add));
      if (!d.isAfter(now)) continue;
      if (a.days.isEmpty || a.days.contains(d.weekday)) return d;
    }
    // Unreachable for valid input; safe fallback = same time tomorrow.
    return DateTime(now.year, now.month, now.day, a.hour, a.minute)
        .add(const Duration(days: 1));
  }

  /// The earliest of today's [prayerTimes] strictly after [now], or null if
  /// they have all passed (the service then recomputes for the next day).
  static DateTime? prayer(List<DateTime> prayerTimes, DateTime now) {
    DateTime? soonest;
    for (final t in prayerTimes) {
      if (t.isAfter(now) && (soonest == null || t.isBefore(soonest))) {
        soonest = t;
      }
    }
    return soonest;
  }
}
