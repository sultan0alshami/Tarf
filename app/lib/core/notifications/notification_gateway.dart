import 'permission_state.dart';
import 'scheduled_item.dart';

/// The ONLY impure surface in Phase 2. Wraps flutter_local_notifications
/// (zoned scheduling + exact-alarm/notification permission requests) so all
/// scheduling logic is unit-testable against [FakeNotificationGateway].
abstract interface class NotificationGateway {
  /// Create channels (Android), set up tz, register tap handlers. Idempotent.
  Future<void> init();

  /// Schedule [item] to fire at [fireAt] (local wall-clock). Overwrites any
  /// prior schedule with the same notificationId.
  Future<void> schedule(ScheduledItem item, DateTime fireAt);

  /// Cancel a single scheduled notification by its [notificationId].
  Future<void> cancel(int notificationId);

  /// Cancel everything Tarf scheduled.
  Future<void> cancelAll();

  /// Current OS notification authorization (queried, not requested).
  Future<PermissionStatus> queryNotificationPermission();

  /// Show the OS notification permission prompt; returns the result.
  Future<PermissionStatus> requestNotificationPermission();

  /// Android 12+ exact-alarm consent. Non-Android returns granted (n/a).
  Future<PermissionStatus> requestExactAlarmPermission();

  /// Android 12+ exact-alarm capability check (canScheduleExactAlarms).
  Future<PermissionStatus> queryExactAlarmPermission();
}

/// In-memory test double. Records calls; programmable permission results.
class FakeNotificationGateway implements NotificationGateway {
  FakeNotificationGateway({
    this.notificationResult = PermissionStatus.granted,
    this.exactAlarmResult = PermissionStatus.granted,
  });

  PermissionStatus notificationResult;
  PermissionStatus exactAlarmResult;

  final List<(ScheduledItem, DateTime)> scheduled = [];
  int initCount = 0;
  int notificationRequests = 0;
  int exactAlarmRequests = 0;
  int cancelAllCount = 0;

  @override
  Future<void> init() async => initCount++;

  @override
  Future<void> schedule(ScheduledItem item, DateTime fireAt) async {
    scheduled
      ..removeWhere((e) => e.$1.notificationId == item.notificationId)
      ..add((item, fireAt));
  }

  @override
  Future<void> cancel(int notificationId) async =>
      scheduled.removeWhere((e) => e.$1.notificationId == notificationId);

  @override
  Future<void> cancelAll() async {
    cancelAllCount++;
    scheduled.clear();
  }

  @override
  Future<PermissionStatus> queryNotificationPermission() async =>
      notificationResult;

  @override
  Future<PermissionStatus> requestNotificationPermission() async {
    notificationRequests++;
    return notificationResult;
  }

  @override
  Future<PermissionStatus> requestExactAlarmPermission() async {
    exactAlarmRequests++;
    return exactAlarmResult;
  }

  @override
  Future<PermissionStatus> queryExactAlarmPermission() async =>
      exactAlarmResult;
}
