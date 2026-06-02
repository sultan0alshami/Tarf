import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'background_capability.dart';
import 'notification_service.dart';
import 'permission_state.dart';

/// Why background delivery is degraded (null = not degraded).
enum DegradedReason {
  /// Platform cannot deliver when closed (web/extension) — foreground only.
  platformForegroundOnly,

  /// User denied/never granted notifications.
  notificationsDenied,

  /// Notifications granted but exact-alarm consent denied (timing may drift).
  exactAlarmDenied,
}

/// The honest background-delivery status Phase 3's banner renders.
class BackgroundDeliveryStatus {
  const BackgroundDeliveryStatus({required this.reason});

  /// null when delivery is fully reliable on this platform.
  final DegradedReason? reason;

  bool get isDegraded => reason != null;
}

/// Overridable so tests pin a platform; defaults to runtime detection.
final platformCapabilityProvider = Provider<BackgroundCapability>(
  (ref) => BackgroundCapability.detect(),
);

/// Combines platform capability + permission state into a single honest status.
final backgroundDeliveryStatusProvider =
    Provider<BackgroundDeliveryStatus>((ref) {
  final cap = ref.watch(platformCapabilityProvider);
  final perm = ref.watch(permissionStateProvider);

  // 1) Platform can't deliver when closed -> foreground-only, always degraded.
  if (!cap.deliversWhenClosed) {
    return const BackgroundDeliveryStatus(
        reason: DegradedReason.platformForegroundOnly);
  }
  // 2) Notifications not usable -> degraded.
  if (!perm.canSchedule) {
    return const BackgroundDeliveryStatus(
        reason: DegradedReason.notificationsDenied);
  }
  // 3) Exact alarms supported but consent denied -> soft (timing) degrade.
  if (cap.supportsExactAlarms &&
      (perm.exactAlarm == PermissionStatus.denied ||
          perm.exactAlarm == PermissionStatus.permanentlyDenied)) {
    return const BackgroundDeliveryStatus(
        reason: DegradedReason.exactAlarmDenied);
  }
  return const BackgroundDeliveryStatus(reason: null);
});
