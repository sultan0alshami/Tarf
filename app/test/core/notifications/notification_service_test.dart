import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/notifications/notification_gateway.dart';
import 'package:tarf/core/notifications/notification_service.dart';
import 'package:tarf/core/notifications/permission_state.dart';
import 'package:tarf/core/notifications/scheduled_item.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/alarm/application/alarms_controller.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';

ProviderContainer _container(
  SharedPreferences prefs,
  FakeNotificationGateway gateway,
) =>
    ProviderContainer(overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationGatewayProvider.overrideWithValue(gateway),
    ]);

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

  group('NotificationService.reconcile', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    // Default EyeCareConfig enables all five prayers, so the standard-alarm
    // tests below disable prayer alarms to isolate the standard-alarm count.
    const noPrayers = EyeCareConfig(prayerAlarmsEnabled: {});

    test('no scheduling when notifications not granted', () async {
      final g =
          FakeNotificationGateway(notificationResult: PermissionStatus.denied);
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      await c.read(eyeCareConfigProvider.notifier).update(noPrayers);
      await c
          .read(alarmsControllerProvider.notifier)
          .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));
      // Permission state denied.
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled, isEmpty);
    });

    test('schedules one enabled standard alarm at its next fire', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(
          PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      await c.read(eyeCareConfigProvider.notifier).update(noPrayers);
      await c.read(alarmsControllerProvider.notifier).upsert(
          const AlarmItem(id: 'a1', hour: 9, minute: 0, days: {1, 2, 3, 4, 5}));
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled.length, 1);
      expect(g.scheduled.single.$1.id, 'a1');
      expect(g.scheduled.single.$1.kind, ScheduledKind.standardAlarm);
    });

    test('disabled alarms are not scheduled; toggling reschedules', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(
          PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      await c.read(eyeCareConfigProvider.notifier).update(noPrayers);
      await c.read(alarmsControllerProvider.notifier).upsert(
          const AlarmItem(id: 'a1', hour: 9, minute: 0, enabled: false));
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled, isEmpty);

      await c.read(alarmsControllerProvider.notifier).toggle('a1');
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled.length, 1);
    });

    test('reconcile is idempotent (cancelAll then reschedule)', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(
          PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      await c.read(eyeCareConfigProvider.notifier).update(noPrayers);
      await c
          .read(alarmsControllerProvider.notifier)
          .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));
      await c.read(notificationServiceProvider.notifier).reconcile();
      await c.read(notificationServiceProvider.notifier).reconcile();
      expect(g.scheduled.length, 1); // not doubled
      expect(g.cancelAllCount, 2); // each reconcile clears then rebuilds
    });

    test('enabled prayer alarms are scheduled by kind prayerAlarm', () async {
      final g = FakeNotificationGateway();
      final c = _container(prefs, g);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(
          PermissionState.initial
              .afterNotificationResult(PermissionStatus.granted));
      // Default config enables all five prayers.
      await c.read(eyeCareConfigProvider.notifier).update(const EyeCareConfig());
      await c.read(notificationServiceProvider.notifier).reconcile();
      final prayerCount = g.scheduled
          .where((e) => e.$1.kind == ScheduledKind.prayerAlarm)
          .length;
      expect(prayerCount, greaterThanOrEqualTo(1)); // at least the next one today
    });
  });
}
