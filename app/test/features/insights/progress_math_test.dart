import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/features/insights/domain/daily_progress.dart';

Map<String, DailyProgress> mk(Map<String, int> daySessions) => {
      for (final e in daySessions.entries)
        e.key: DailyProgress(
          day: e.key,
          sessions: e.value,
          focusMinutes: e.value * 25,
        ),
    };

void main() {
  final today = DateTime(2026, 5, 31, 12);

  group('ProgressMath', () {
    test('lastDays returns n days oldest-first, filling gaps with empty', () {
      final week = ProgressMath.lastDays(mk({'2026-05-31': 2}), today, 7);
      expect(week.length, 7);
      expect(week.last.day, '2026-05-31');
      expect(week.last.sessions, 2);
      expect(week.first.sessions, 0);
    });

    test('currentStreak counts consecutive days including today', () {
      final all = mk({
        '2026-05-31': 1,
        '2026-05-30': 1,
        '2026-05-29': 1,
        '2026-05-27': 1, // gap at 28 breaks it
      });
      expect(ProgressMath.currentStreak(all, today), 3);
    });

    test('streak survives a missing today if yesterday counts', () {
      final all = mk({'2026-05-30': 1, '2026-05-29': 1});
      expect(ProgressMath.currentStreak(all, today), 2);
    });

    test('no streak when neither today nor yesterday counts', () {
      expect(ProgressMath.currentStreak(mk({'2026-05-20': 5}), today), 0);
    });

    test('toCsv has a header and day-sorted rows', () {
      final csv = ProgressMath.toCsv(mk({'2026-05-31': 2, '2026-05-30': 1}));
      final lines = csv.split('\n');
      expect(lines.first, 'day,focusMinutes,sessions,breaksTaken,breaksSkipped');
      expect(lines[1].startsWith('2026-05-30'), isTrue);
      expect(lines[2].startsWith('2026-05-31'), isTrue);
    });
  });
}
