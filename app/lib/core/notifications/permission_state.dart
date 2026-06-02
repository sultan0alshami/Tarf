/// Coarse cross-platform permission status. 'limited' models iOS provisional
/// (quiet delivery) which is still schedulable.
enum PermissionStatus { notDetermined, granted, limited, denied, permanentlyDenied }

/// Immutable snapshot of the two permissions Phase 2 cares about, plus a
/// re-ask budget. Persisted as JSON so the priming flow does not nag.
class PermissionState {
  const PermissionState({
    required this.notifications,
    required this.exactAlarm,
    required this.deniedCount,
  });

  final PermissionStatus notifications;
  final PermissionStatus exactAlarm;

  /// How many times the notification prompt was denied (drives the one re-ask).
  final int deniedCount;

  static const initial = PermissionState(
    notifications: PermissionStatus.notDetermined,
    exactAlarm: PermissionStatus.notDetermined,
    deniedCount: 0,
  );

  bool get askedOnce => notifications != PermissionStatus.notDetermined;

  /// Provisional/limited and full grant both allow scheduling.
  bool get canSchedule =>
      notifications == PermissionStatus.granted ||
      notifications == PermissionStatus.limited;

  /// We may still call the OS prompt: never asked, or denied exactly once.
  bool get canRequestNotifications =>
      notifications == PermissionStatus.notDetermined ||
      (notifications == PermissionStatus.denied && deniedCount < 2);

  PermissionState afterNotificationResult(PermissionStatus result) {
    // Two denials => treat as permanently denied (OS stops prompting anyway).
    final nextDenied =
        result == PermissionStatus.denied ? deniedCount + 1 : deniedCount;
    final status = (result == PermissionStatus.denied && nextDenied >= 2)
        ? PermissionStatus.permanentlyDenied
        : result;
    return PermissionState(
      notifications: status,
      exactAlarm: exactAlarm,
      deniedCount: nextDenied,
    );
  }

  PermissionState afterExactAlarmResult(PermissionStatus result) =>
      PermissionState(
        notifications: notifications,
        exactAlarm: result,
        deniedCount: deniedCount,
      );

  Map<String, Object?> toJson() => {
        'notif': notifications.name,
        'exact': exactAlarm.name,
        'deniedCount': deniedCount,
      };

  factory PermissionState.fromJson(Map<String, Object?> j) => PermissionState(
        notifications: PermissionStatus.values
            .byName((j['notif'] as String?) ?? 'notDetermined'),
        exactAlarm: PermissionStatus.values
            .byName((j['exact'] as String?) ?? 'notDetermined'),
        deniedCount: (j['deniedCount'] as int?) ?? 0,
      );
}
