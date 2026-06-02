import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/notifications/notification_gateway.dart';
import 'package:tarf/core/notifications/permission_state.dart';
import 'package:tarf/core/notifications/scheduled_item.dart';

void main() {
  group('FakeNotificationGateway', () {
    test('records scheduled items and can cancel by notificationId', () async {
      final g = FakeNotificationGateway();
      const item = ScheduledItem(
          kind: ScheduledKind.standardAlarm,
          id: 'a1',
          title: 'Wake',
          body: '',
          soundId: 'bell');
      final at = DateTime(2026, 6, 1, 6, 30);
      await g.schedule(item, at);
      expect(g.scheduled.single.$1.id, 'a1');
      expect(g.scheduled.single.$2, at);

      await g.cancel(item.notificationId);
      expect(g.scheduled, isEmpty);
    });

    test('cancelAll clears everything', () async {
      final g = FakeNotificationGateway();
      await g.schedule(
          const ScheduledItem(
              kind: ScheduledKind.prayerAlarm,
              id: 'fajr',
              title: 'F',
              body: '',
              soundId: 'default'),
          DateTime(2026, 6, 1, 4, 10));
      await g.cancelAll();
      expect(g.scheduled, isEmpty);
    });

    test('permission requests return the programmed result', () async {
      final g = FakeNotificationGateway(
        notificationResult: PermissionStatus.granted,
        exactAlarmResult: PermissionStatus.denied,
      );
      expect(await g.requestNotificationPermission(), PermissionStatus.granted);
      expect(await g.requestExactAlarmPermission(), PermissionStatus.denied);
      expect(g.notificationRequests, 1);
    });
  });
}
