import 'package:flutter_test/flutter_test.dart';
import 'package:tarf/core/notifications/permission_state.dart';

void main() {
  group('PermissionState', () {
    test('initial state is notDetermined, not asked', () {
      const s = PermissionState.initial;
      expect(s.notifications, PermissionStatus.notDetermined);
      expect(s.exactAlarm, PermissionStatus.notDetermined);
      expect(s.askedOnce, isFalse);
      expect(s.canRequestNotifications, isTrue);
    });

    test('granting notifications sets granted + askedOnce', () {
      final s = PermissionState.initial
          .afterNotificationResult(PermissionStatus.granted);
      expect(s.notifications, PermissionStatus.granted);
      expect(s.askedOnce, isTrue);
      expect(s.canRequestNotifications, isFalse); // already granted
    });

    test('denied once still allows a single re-ask; twice is permanent', () {
      final once = PermissionState.initial
          .afterNotificationResult(PermissionStatus.denied);
      expect(once.notifications, PermissionStatus.denied);
      expect(once.canRequestNotifications, isTrue); // one gentle re-ask
      final twice = once.afterNotificationResult(PermissionStatus.denied);
      expect(twice.notifications, PermissionStatus.permanentlyDenied);
      expect(twice.canRequestNotifications, isFalse); // -> deep-link only
    });

    test('limited (iOS provisional) is a usable grant for scheduling', () {
      final s = PermissionState.initial
          .afterNotificationResult(PermissionStatus.limited);
      expect(s.notifications, PermissionStatus.limited);
      expect(s.canSchedule, isTrue); // provisional delivers quietly
    });

    test('exact-alarm denial does not block notification scheduling', () {
      final s = PermissionState.initial
          .afterNotificationResult(PermissionStatus.granted)
          .afterExactAlarmResult(PermissionStatus.denied);
      expect(s.exactAlarm, PermissionStatus.denied);
      expect(s.canSchedule, isTrue);
    });

    test('json round-trips', () {
      final s = PermissionState.initial
          .afterNotificationResult(PermissionStatus.granted)
          .afterExactAlarmResult(PermissionStatus.granted);
      final back = PermissionState.fromJson(s.toJson());
      expect(back.notifications, PermissionStatus.granted);
      expect(back.exactAlarm, PermissionStatus.granted);
      expect(back.askedOnce, isTrue);
    });
  });
}
