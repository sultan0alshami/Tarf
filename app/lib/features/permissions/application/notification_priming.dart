import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/notifications/background_delivery_status.dart';
import '../../../core/notifications/notification_service.dart';
import '../../../core/settings/settings_controller.dart';
import '../presentation/notification_priming_sheet.dart';

/// Runs the one-time notification priming flow the first time the user lands on
/// the Alarm tab. This is the REAL production entry point that turns the calm
/// rationale sheet into actual OS permission requests and a persisted permission
/// state — which the [NotificationService] listener then reconciles into a live
/// schedule.
///
/// Sequence (honesty principle — we never prompt the OS cold):
///   1. mark the sheet "shown" so we prompt exactly once, whatever the choice;
///   2. show the calm rationale sheet;
///   3. on [PrimingChoice.enable], request OS notification permission via the
///      gateway and record the result (this mutates permissionStateProvider,
///      whose listener calls reconcile() → scheduling begins);
///   4. on Android (capability supports exact alarms), also request exact-alarm
///      consent and record it.
///
/// All platform/plugin work lives behind the gateway, so this stays unit/widget
/// testable with a FakeNotificationGateway. Safe to call on every Alarm-tab
/// build: it returns immediately once [AppSettings.notifPrimingShown] is set.
Future<void> maybeRunNotificationPriming(
  BuildContext context,
  WidgetRef ref,
) async {
  final settings = ref.read(settingsControllerProvider);
  if (settings.notifPrimingShown) return;

  // Mark shown up front so a dismiss (tap outside / Not now) never re-prompts.
  await ref.read(settingsControllerProvider.notifier).markNotifPrimingShown();

  if (!context.mounted) return;
  final choice = await showNotificationPrimingSheet(context);
  if (choice != PrimingChoice.enable) return;

  final gateway = ref.read(notificationGatewayProvider);
  final permissions = ref.read(permissionStateProvider.notifier);

  final notifResult = await gateway.requestNotificationPermission();
  await permissions.recordNotificationResult(notifResult);

  // Exact-alarm consent is meaningful only where the platform supports it
  // (Android). Reading the capability provider keeps this widget platform-free
  // and lets tests pin the platform.
  final capability = ref.read(platformCapabilityProvider);
  if (capability.supportsExactAlarms) {
    final exactResult = await gateway.requestExactAlarmPermission();
    await permissions.recordExactAlarmResult(exactResult);
  }
}
