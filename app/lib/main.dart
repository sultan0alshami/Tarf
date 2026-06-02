import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/audio/audio_providers.dart';
import 'core/data/prefs_repository.dart';
import 'core/data/repository_providers.dart';
import 'core/notifications/flutter_notification_gateway.dart';
import 'core/notifications/notification_service.dart';
import 'core/settings/settings_controller.dart';
import 'firebase/firebase_flags.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // The single local-first persistence seam. Every feature writes through this.
  // When cloud is enabled (owner runs flutterfire configure + builds with
  // --dart-define=TARF_CLOUD=true), main wires a CloudMirror here and overrides
  // the auth/cloudAccount providers with Firebase impls; see docs/firebase-setup.md.
  final repo = PrefsRepository(prefs);

  // Cloud is OFF unless compiled with --dart-define=TARF_CLOUD=true AND
  // firebase_options.dart is present (owner-generated; absent -> guest mode).
  const compileCloud = bool.fromEnvironment('TARF_CLOUD');
  const configPresent = false; // flip to true after flutterfire configure wires options
  const flags = FirebaseFlags(configPresent: configPresent, compileEnabled: compileCloud);

  final gateway = FlutterNotificationGateway();
  await gateway.init();

  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      tarfRepositoryProvider.overrideWithValue(repo),
      firebaseFlagsProvider.overrideWithValue(flags),
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
