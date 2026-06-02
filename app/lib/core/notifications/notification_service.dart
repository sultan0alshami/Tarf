import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/alarm/application/alarms_controller.dart';
import '../../features/eyecare/application/eyecare_config_controller.dart';
import '../../features/eyecare/core/prayer_service.dart';
import '../settings/settings_controller.dart';
import 'next_fire.dart';
import 'notification_gateway.dart';
import 'permission_state.dart';
import 'scheduled_item.dart';

/// Injected gateway. main() overrides with FlutterNotificationGateway; tests
/// override with FakeNotificationGateway.
final notificationGatewayProvider = Provider<NotificationGateway>(
  (ref) =>
      throw UnimplementedError('notificationGatewayProvider must be overridden'),
);

/// Persisted permission snapshot. Updated by the priming flow (Task 13).
class PermissionStateController extends Notifier<PermissionState> {
  static const _key = 'tarf.permissions.v1';

  @override
  PermissionState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return PermissionState.initial;
    try {
      return PermissionState.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return PermissionState.initial;
    }
  }

  Future<void> _persist(PermissionState next) async {
    state = next;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode(next.toJson()));
  }

  Future<void> recordNotificationResult(PermissionStatus r) =>
      _persist(state.afterNotificationResult(r));

  Future<void> recordExactAlarmResult(PermissionStatus r) =>
      _persist(state.afterExactAlarmResult(r));

  /// Test seam (synchronous, no I/O wait needed in unit tests).
  void setForTest(PermissionState s) => state = s;
}

final permissionStateProvider =
    NotifierProvider<PermissionStateController, PermissionState>(
        PermissionStateController.new);

/// Orchestrates OS scheduling. Value = whether background scheduling is active
/// (permission granted/limited). Call [reconcile] after any alarm/config change.
class NotificationService extends Notifier<bool> {
  @override
  bool build() => false;

  NotificationGateway get _gateway => ref.read(notificationGatewayProvider);

  static const _prayerIds = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  /// Build the desired set of items from the three sources.
  List<(ScheduledItem, DateTime)> _desired(DateTime now) {
    final out = <(ScheduledItem, DateTime)>[];
    final alarms = ref.read(alarmsControllerProvider);
    for (final a in alarms) {
      if (!a.enabled) continue;
      final at = NextFire.standard(a, now);
      out.add((
        ScheduledItem(
          kind: ScheduledKind.standardAlarm,
          id: a.id,
          title: a.label.isEmpty ? 'Alarm' : a.label,
          body: '',
          soundId: a.sound,
        ),
        at,
      ));
    }
    final cfg = ref.read(eyeCareConfigProvider);
    if (cfg.prayerAlarmsEnabled.isNotEmpty) {
      final times = PrayerService.timesFor(
        latitude: cfg.prayerLatitude,
        longitude: cfg.prayerLongitude,
        day: now,
        method: cfg.prayerMethod,
        madhab: cfg.prayerMadhab,
      );
      for (var i = 0; i < _prayerIds.length && i < times.length; i++) {
        if (!cfg.prayerAlarmsEnabled.contains(_prayerIds[i])) continue;
        var at = times[i];
        if (!at.isAfter(now)) {
          // Today's passed; schedule tomorrow's computed time.
          final tomorrow = now.add(const Duration(days: 1));
          final t2 = PrayerService.timesFor(
            latitude: cfg.prayerLatitude,
            longitude: cfg.prayerLongitude,
            day: tomorrow,
            method: cfg.prayerMethod,
            madhab: cfg.prayerMadhab,
          );
          at = t2[i];
        }
        out.add((
          ScheduledItem(
            kind: ScheduledKind.prayerAlarm,
            id: _prayerIds[i],
            title: _prayerIds[i],
            body: '',
            soundId: 'default',
          ),
          at,
        ));
      }
    }
    return out;
  }

  /// Cancel everything and reschedule the desired set. Honest: only schedules
  /// if the user has granted/limited notification permission.
  Future<void> reconcile() async {
    final perm = ref.read(permissionStateProvider);
    await _gateway.cancelAll();
    if (!perm.canSchedule) {
      state = false;
      return;
    }
    final now = DateTime.now();
    for (final (item, at) in _desired(now)) {
      await _gateway.schedule(item, at);
    }
    state = true;
  }
}

final notificationServiceProvider =
    NotifierProvider<NotificationService, bool>(NotificationService.new);
