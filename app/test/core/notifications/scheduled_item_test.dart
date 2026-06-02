import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/notifications/scheduled_item.dart';

void main() {
  group('ScheduledItem', () {
    final fireAt = DateTime(2026, 6, 1, 6, 30);

    test('guardKey is kind:id:minute and stable', () {
      const item = ScheduledItem(
        kind: ScheduledKind.standardAlarm,
        id: 'a1',
        title: 'Wake',
        body: '',
        soundId: 'bell',
      );
      final key = item.guardKeyFor(fireAt);
      expect(key, 'standardAlarm:a1:2026-06-01-06-30');
      expect(item.guardKeyFor(fireAt), key); // deterministic
    });

    test('notificationId is a stable non-negative 31-bit hash of kind+id', () {
      const a = ScheduledItem(
          kind: ScheduledKind.prayerAlarm,
          id: 'fajr',
          title: 'Fajr',
          body: '',
          soundId: 'default');
      const b = ScheduledItem(
          kind: ScheduledKind.prayerAlarm,
          id: 'fajr',
          title: 'Fajr2',
          body: 'x',
          soundId: 'calm');
      expect(a.notificationId, b.notificationId); // id+kind only
      expect(a.notificationId, greaterThanOrEqualTo(0));
      expect(a.notificationId, lessThan(1 << 31));
      const c = ScheduledItem(
          kind: ScheduledKind.standardAlarm,
          id: 'fajr',
          title: 'x',
          body: '',
          soundId: 'default');
      expect(a.notificationId == c.notificationId, isFalse); // kind matters
    });

    test('payload round-trips through encode/decode', () {
      const item = ScheduledItem(
          kind: ScheduledKind.eyeBreak,
          id: 'eye',
          title: 'Rest',
          body: 'Look away',
          soundId: 'chime');
      final decoded = ScheduledItem.decodePayload(item.encodePayload(fireAt));
      expect(decoded.kind, ScheduledKind.eyeBreak);
      expect(decoded.id, 'eye');
      expect(decoded.guardKey, 'eyeBreak:eye:2026-06-01-06-30');
    });
  });
}
