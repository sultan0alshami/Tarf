import 'package:flutter/foundation.dart';

import '../../../core/time/clock.dart';

/// One day's aggregated activity. Keyed by local `yyyy-MM-dd` (see [dayKey]).
@immutable
class DailyProgress {
  const DailyProgress({
    required this.day,
    this.focusMinutes = 0,
    this.sessions = 0,
    this.breaksTaken = 0,
    this.breaksSkipped = 0,
  });

  factory DailyProgress.empty(String day) => DailyProgress(day: day);

  final String day;
  final int focusMinutes;
  final int sessions;
  final int breaksTaken;
  final int breaksSkipped;

  DailyProgress copyWith({
    int? focusMinutes,
    int? sessions,
    int? breaksTaken,
    int? breaksSkipped,
  }) =>
      DailyProgress(
        day: day,
        focusMinutes: focusMinutes ?? this.focusMinutes,
        sessions: sessions ?? this.sessions,
        breaksTaken: breaksTaken ?? this.breaksTaken,
        breaksSkipped: breaksSkipped ?? this.breaksSkipped,
      );

  Map<String, Object?> toJson() => {
        'day': day,
        'fm': focusMinutes,
        's': sessions,
        'bt': breaksTaken,
        'bs': breaksSkipped,
      };

  factory DailyProgress.fromJson(Map<String, Object?> j) => DailyProgress(
        day: j['day']! as String,
        focusMinutes: (j['fm'] as int?) ?? 0,
        sessions: (j['s'] as int?) ?? 0,
        breaksTaken: (j['bt'] as int?) ?? 0,
        breaksSkipped: (j['bs'] as int?) ?? 0,
      );
}

/// Pure helpers over the day-keyed progress map (testable without storage).
abstract final class ProgressMath {
  ProgressMath._();

  /// The most recent [n] days (oldest first), filling gaps with empty days.
  static List<DailyProgress> lastDays(
    Map<String, DailyProgress> all,
    DateTime today,
    int n,
  ) {
    final out = <DailyProgress>[];
    for (var i = n - 1; i >= 0; i--) {
      final d = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      final key = dayKey(d);
      out.add(all[key] ?? DailyProgress.empty(key));
    }
    return out;
  }

  /// Consecutive days up to and including [today] with at least one session.
  /// A missing today does NOT break a streak earned through yesterday.
  static int currentStreak(Map<String, DailyProgress> all, DateTime today) {
    var streak = 0;
    var cursor = DateTime(today.year, today.month, today.day);
    final todayKey = dayKey(cursor);
    final todayCounts = (all[todayKey]?.sessions ?? 0) > 0;
    if (!todayCounts) cursor = cursor.subtract(const Duration(days: 1));
    while ((all[dayKey(cursor)]?.sessions ?? 0) > 0) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// CSV with a header row, oldest day first.
  static String toCsv(Map<String, DailyProgress> all) {
    final rows = <String>['day,focusMinutes,sessions,breaksTaken,breaksSkipped'];
    final keys = all.keys.toList()..sort();
    for (final k in keys) {
      final p = all[k]!;
      rows.add('${p.day},${p.focusMinutes},${p.sessions},'
          '${p.breaksTaken},${p.breaksSkipped}');
    }
    return rows.join('\n');
  }
}
