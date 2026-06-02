import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/audio/audio_providers.dart';
import 'core/notifications/flutter_notification_gateway.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/settings_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final gateway = FlutterNotificationGateway();
  await gateway.init();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      notificationGatewayProvider.overrideWithValue(gateway),
      tarfAudioServiceProvider.overrideWith((ref) {
        final svc = buildRealAudioService();
        ref.onDispose(svc.dispose);
        return svc;
      }),
    ],
  );
  // Reconcile on every cold start (re-arms after reboot on Android) and keep
  // the schedule in sync with future alarm/config/permission changes. The
  // reconcile runs in the background; we do not block first frame on it.
  final notifier = container.read(notificationServiceProvider.notifier)
    ..listenForChanges();
  unawaited(notifier.reconcile());

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TarfApp(),
    ),
  );
}
