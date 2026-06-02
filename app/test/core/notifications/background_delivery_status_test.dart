import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/notifications/background_capability.dart';
import 'package:tarf/core/notifications/background_delivery_status.dart';
import 'package:tarf/core/notifications/notification_service.dart';
import 'package:tarf/core/notifications/permission_state.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/l10n/app_localizations_en.dart';

void main() {
  group('BackgroundCapability', () {
    test('android claims exact-capable background delivery', () {
      const cap = BackgroundCapability.android;
      expect(cap.deliversWhenClosed, isTrue);
      expect(cap.supportsExactAlarms, isTrue);
    });
    test('web only delivers while the tab is open', () {
      const cap = BackgroundCapability.web;
      expect(cap.deliversWhenClosed, isFalse);
      expect(cap.supportsExactAlarms, isFalse);
    });
    test('ios delivers when closed but without exact alarms', () {
      const cap = BackgroundCapability.ios;
      expect(cap.deliversWhenClosed, isTrue);
      expect(cap.supportsExactAlarms, isFalse);
    });
  });

  group('backgroundDeliveryStatusProvider', () {
    late SharedPreferences prefs;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    });

    ProviderContainer build(BackgroundCapability cap) => ProviderContainer(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            platformCapabilityProvider.overrideWithValue(cap),
          ],
        );

    test('degraded when notifications denied even on capable platform', () {
      final c = build(BackgroundCapability.android);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(PermissionState
          .initial
          .afterNotificationResult(PermissionStatus.denied));
      final status = c.read(backgroundDeliveryStatusProvider);
      expect(status.isDegraded, isTrue);
      expect(status.reason, DegradedReason.notificationsDenied);
    });

    test('degraded (foreground-only) on web regardless of permission', () {
      final c = build(BackgroundCapability.web);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(PermissionState
          .initial
          .afterNotificationResult(PermissionStatus.granted));
      final status = c.read(backgroundDeliveryStatusProvider);
      expect(status.isDegraded, isTrue);
      expect(status.reason, DegradedReason.platformForegroundOnly);
    });

    test('not degraded on android with granted notifications + exact alarm', () {
      final c = build(BackgroundCapability.android);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(PermissionState
          .initial
          .afterNotificationResult(PermissionStatus.granted)
          .afterExactAlarmResult(PermissionStatus.granted));
      final status = c.read(backgroundDeliveryStatusProvider);
      expect(status.isDegraded, isFalse);
      expect(status.reason, isNull);
    });

    test('inexact on android when exact-alarm denied is a soft degrade', () {
      final c = build(BackgroundCapability.android);
      addTearDown(c.dispose);
      c.read(permissionStateProvider.notifier).setForTest(PermissionState
          .initial
          .afterNotificationResult(PermissionStatus.granted)
          .afterExactAlarmResult(PermissionStatus.denied));
      final status = c.read(backgroundDeliveryStatusProvider);
      expect(status.isDegraded, isTrue);
      expect(status.reason, DegradedReason.exactAlarmDenied);
    });
  });

  test('degraded l10n keys are generated', () {
    final en = AppLocalizationsEn();
    expect(en.bgRemindersOff.isNotEmpty, isTrue);
    expect(en.bgForegroundOnlyPlatform.isNotEmpty, isTrue);
    expect(en.bgExactAlarmOff.isNotEmpty, isTrue);
    expect(en.notifPrimingTitle.isNotEmpty, isTrue);
  });
}
