import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/notifications/background_capability.dart';
import 'package:tarf/core/notifications/background_delivery_status.dart';
import 'package:tarf/core/notifications/notification_gateway.dart';
import 'package:tarf/core/notifications/notification_service.dart';
import 'package:tarf/core/notifications/permission_state.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/alarm/application/alarms_controller.dart';
import 'package:tarf/features/alarm/domain/alarm_item.dart';
import 'package:tarf/features/alarm/presentation/alarm_screen.dart';
import 'package:tarf/features/eyecare/application/eyecare_config_controller.dart';
import 'package:tarf/features/eyecare/domain/eyecare_config.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

/// Mounts the real Alarm tab so the production priming entry point fires.
ProviderScope _app(
  SharedPreferences prefs,
  FakeNotificationGateway gateway, {
  BackgroundCapability capability = BackgroundCapability.android,
}) =>
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        notificationGatewayProvider.overrideWithValue(gateway),
        platformCapabilityProvider.overrideWithValue(capability),
      ],
      child: MaterialApp(
        locale: const Locale('en'),
        theme: TarfTheme.dark(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const AlarmScreen(),
      ),
    );

void main() {
  testWidgets(
      'first Alarm-tab visit primes, grant schedules via the gateway',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gateway = FakeNotificationGateway(
      notificationResult: PermissionStatus.granted,
      exactAlarmResult: PermissionStatus.granted,
    );

    await tester.pumpWidget(_app(prefs, gateway));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AlarmScreen)),
    );
    // The permission grant must drive a reschedule (this is what main() wires).
    container.read(notificationServiceProvider.notifier).listenForChanges();
    // No prayer alarms so the standard alarm count is unambiguous; one enabled
    // standard alarm to schedule.
    await container
        .read(eyeCareConfigProvider.notifier)
        .update(const EyeCareConfig(prayerAlarmsEnabled: {}));
    await container
        .read(alarmsControllerProvider.notifier)
        .upsert(const AlarmItem(id: 'a1', hour: 9, minute: 0));

    // The post-frame callback shows the priming sheet.
    await tester.pumpAndSettle();
    expect(find.text('Enable'), findsOneWidget);
    expect(gateway.notificationRequests, 0); // not prompted cold

    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    // Gateway was asked for both permissions, the state recorded the grant,
    // and the listener reconciled into a real scheduled notification.
    expect(gateway.notificationRequests, 1);
    expect(gateway.exactAlarmRequests, 1); // Android capability
    expect(
      container.read(permissionStateProvider).notifications,
      PermissionStatus.granted,
    );
    expect(gateway.scheduled.length, 1);
    expect(gateway.scheduled.single.$1.id, 'a1');

    // And it never re-prompts.
    expect(
      container.read(settingsControllerProvider).notifPrimingShown,
      isTrue,
    );
  });

  testWidgets('Not now marks shown and never touches the gateway',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gateway = FakeNotificationGateway();

    await tester.pumpWidget(_app(prefs, gateway));
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AlarmScreen)),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Not now'));
    await tester.pumpAndSettle();

    expect(gateway.notificationRequests, 0);
    expect(gateway.scheduled, isEmpty);
    expect(
      container.read(permissionStateProvider).notifications,
      PermissionStatus.notDetermined,
    );
    expect(
      container.read(settingsControllerProvider).notifPrimingShown,
      isTrue, // shown once regardless of choice
    );
  });

  testWidgets('does not prompt when already shown', (tester) async {
    SharedPreferences.setMockInitialValues({
      'tarf.app_settings.v1': '{"notifPrimingShown":true}',
    });
    final prefs = await SharedPreferences.getInstance();
    final gateway = FakeNotificationGateway();

    await tester.pumpWidget(_app(prefs, gateway));
    await tester.pumpAndSettle();

    expect(find.text('Enable'), findsNothing);
    expect(gateway.notificationRequests, 0);
  });

  testWidgets('non-Android does not request exact-alarm consent',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final gateway = FakeNotificationGateway(
      notificationResult: PermissionStatus.granted,
    );

    await tester.pumpWidget(
      _app(prefs, gateway, capability: BackgroundCapability.ios),
    );
    final container = ProviderScope.containerOf(
      tester.element(find.byType(AlarmScreen)),
    );
    await container
        .read(eyeCareConfigProvider.notifier)
        .update(const EyeCareConfig(prayerAlarmsEnabled: {}));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Enable'));
    await tester.pumpAndSettle();

    expect(gateway.notificationRequests, 1);
    expect(gateway.exactAlarmRequests, 0); // iOS has no exact-alarm consent
  });
}
