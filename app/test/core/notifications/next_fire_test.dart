import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/notifications/next_fire.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';

void main() {
  group('NextFire.standard', () {
    // Mon 2026-06-01 08:00 local.
    final now = DateTime(2026, 6, 1, 8, 0);

    test('one-shot later today', () {
      const a = AlarmItem(id: 'a', hour: 9, minute: 30); // days empty
      expect(NextFire.standard(a, now), DateTime(2026, 6, 1, 9, 30));
    });

    test('one-shot earlier today rolls to tomorrow', () {
      const a = AlarmItem(id: 'a', hour: 7, minute: 0);
      expect(NextFire.standard(a, now), DateTime(2026, 6, 2, 7, 0));
    });

    test('repeat weekdays from Friday picks Monday', () {
      final fri = DateTime(2026, 6, 5, 22, 0); // Fri
      const a = AlarmItem(id: 'a', hour: 6, minute: 0, days: {1, 2, 3, 4, 5});
      expect(NextFire.standard(a, fri), DateTime(2026, 6, 8, 6, 0)); // Mon
    });

    test('repeat today but time already passed picks same weekday next week',
        () {
      // now Mon 08:00; alarm Mondays only at 06:00 -> next Monday.
      const a = AlarmItem(id: 'a', hour: 6, minute: 0, days: {1});
      expect(NextFire.standard(a, now), DateTime(2026, 6, 8, 6, 0));
    });

    test('exactly now does NOT count as next (strictly after)', () {
      const a = AlarmItem(id: 'a', hour: 8, minute: 0, days: {1});
      expect(NextFire.standard(a, now), DateTime(2026, 6, 8, 8, 0));
    });
  });

  group('NextFire.prayer', () {
    final now = DateTime(2026, 6, 1, 8, 0);
    test('returns the earliest prayer time strictly after now', () {
      final times = [
        DateTime(2026, 6, 1, 4, 10), // passed
        DateTime(2026, 6, 1, 11, 50), // next
        DateTime(2026, 6, 1, 15, 20),
      ];
      expect(NextFire.prayer(times, now), DateTime(2026, 6, 1, 11, 50));
    });

    test('all passed today returns null (caller recomputes for tomorrow)', () {
      final times = [DateTime(2026, 6, 1, 4, 10), DateTime(2026, 6, 1, 7, 0)];
      expect(NextFire.prayer(times, now), isNull);
    });
  });
}
