import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Background tap handler (runs in a separate isolate on some platforms). Must
/// be a top-level or static function annotated for the VM entry point. We keep
/// it minimal: the actual ring/overlay is handled when the app is foregrounded
/// and the DoubleFireGuard reconciles. Heavy work here is unsafe.
@pragma('vm:entry-point')
void notificationBackgroundTap(NotificationResponse response) {
  // No-op: payload is the guard key; foreground handler claims/acts on resume.
}
