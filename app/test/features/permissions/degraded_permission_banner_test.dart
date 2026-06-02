import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarf/core/notifications/background_capability.dart';
import 'package:tarf/core/notifications/background_delivery_status.dart';
import 'package:tarf/core/notifications/notification_service.dart';
import 'package:tarf/core/notifications/permission_state.dart';
import 'package:tarf/core/settings/settings_controller.dart';
import 'package:tarf/features/permissions/presentation/degraded_permission_banner.dart';
import 'package:tarf/l10n/app_localizations.dart';
import 'package:tarf/theme/app_theme.dart';

Future<Widget> _host(
  SharedPreferences prefs,
  BackgroundCapability cap, {
  PermissionState? perm,
}) async {
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      platformCapabilityProvider.overrideWithValue(cap),
    ],
  );
  if (perm != null) {
    container.read(permissionStateProvider.notifier).setForTest(perm);
  }
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      locale: const Locale('en'),
      theme: TarfTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const Scaffold(body: DegradedPermissionBanner()),
    ),
  );
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('hidden when delivery is fully reliable', (tester) async {
    await tester.pumpWidget(await _host(
      prefs,
      BackgroundCapability.android,
      perm: PermissionState.initial
          .afterNotificationResult(PermissionStatus.granted)
          .afterExactAlarmResult(PermissionStatus.granted),
    ));
    await tester.pump();
    // Renders nothing (no warning icon) when not degraded.
    expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
  });

  testWidgets('shows an honest message + icon when notifications denied',
      (tester) async {
    await tester.pumpWidget(await _host(
      prefs,
      BackgroundCapability.android,
      perm: PermissionState.initial
          .afterNotificationResult(PermissionStatus.denied),
    ));
    await tester.pump();
    // Equal non-color cue: a warning icon accompanies the color.
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    // The honest Phase-2 reason message is rendered.
    expect(find.textContaining('Background reminders off'), findsOneWidget);
  });

  testWidgets('shows the foreground-only message on web', (tester) async {
    await tester.pumpWidget(await _host(
      prefs,
      BackgroundCapability.web,
      perm: PermissionState.initial
          .afterNotificationResult(PermissionStatus.granted),
    ));
    await tester.pump();
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    expect(find.textContaining('only while Tarf is open'), findsOneWidget);
  });
}
