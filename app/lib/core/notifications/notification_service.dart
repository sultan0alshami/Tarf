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

  /// Persisted `{alarmId -> armedFireMillis}` for one-shot alarms only. Lets us
  /// detect a one-shot that the OS delivered while the app was closed (so the
  /// foreground `_ring` never toggled it off) and disable it instead of
  /// re-arming it for the next day. Survives process death (the whole point).
  static const _oneShotArmedKey = 'tarf.oneshot_armed.v1';

  bool _listening = false;
  bool _reconciling = false;

  /// Subscribe to the three scheduling inputs; reconcile on any change. Also
  /// reconciles when permission becomes granted. Call once from main() after
  /// init so add/edit/toggle/delete and permission grants re-arm the schedule.
  void listenForChanges() {
    if (_listening) return;
    _listening = true;
    ref.listen(alarmsControllerProvider, (_, _) => reconcile());
    ref.listen(eyeCareConfigProvider, (_, _) => reconcile());
    ref.listen(permissionStateProvider, (_, _) => reconcile());
  }

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

  Map<String, int> _readOneShotArmed() {
    final raw = ref.read(sharedPreferencesProvider).getString(_oneShotArmedKey);
    if (raw == null) return {};
    try {
      return (jsonDecode(raw) as Map<String, Object?>)
          .map((k, v) => MapEntry(k, v as int));
    } catch (_) {
      return {};
    }
  }

  Future<void> _writeOneShotArmed(Map<String, int> map) =>
      ref.read(sharedPreferencesProvider).setString(
            _oneShotArmedKey,
            jsonEncode(map),
          );

  /// Disable any enabled one-shot alarm whose previously-armed fire time is now
  /// in the past: the OS delivered it while the app was closed, so the
  /// foreground `_ring` never toggled it off. Without this, the next reconcile
  /// would compute tomorrow's occurrence and re-arm it, repeating daily forever.
  /// Returns the swept-down armed map (entries for fired/disabled alarms cleared).
  Future<Map<String, int>> _disableFiredOneShots(DateTime now) async {
    final armed = _readOneShotArmed();
    if (armed.isEmpty) return armed;
    final alarms = ref.read(alarmsControllerProvider);
    final controller = ref.read(alarmsControllerProvider.notifier);
    var changed = false;
    for (final entry in armed.entries.toList()) {
      final fireMs = entry.value;
      if (fireMs >= now.millisecondsSinceEpoch) continue; // not fired yet
      final matches = alarms.where((a) => a.id == entry.key);
      final a = matches.isEmpty ? null : matches.first;
      // Only one-shots are tracked; if it is still an enabled one-shot, the
      // delivery already happened in the background -> turn it off.
      if (a != null && a.enabled && a.days.isEmpty) {
        await controller.toggle(a.id);
      }
      armed.remove(entry.key);
      changed = true;
    }
    if (changed) await _writeOneShotArmed(armed);
    return armed;
  }

  /// Cancel everything and reschedule the desired set. Honest: only schedules
  /// if the user has granted/limited notification permission. [now] is injectable
  /// for tests; production passes the wall clock.
  Future<void> reconcile({DateTime? now}) async {
    if (_reconciling) return; // guard re-entrancy (disabling a one-shot relists)
    _reconciling = true;
    try {
      final clock = now ?? DateTime.now();
      final perm = ref.read(permissionStateProvider);
      await _gateway.cancelAll();
      if (!perm.canSchedule) {
        state = false;
        return;
      }
      // Self-heal one-shots the OS already delivered while we were closed.
      await _disableFiredOneShots(clock);

      final armed = _readOneShotArmed();
      final desired = _desired(clock);
      final nextArmed = <String, int>{};
      for (final (item, at) in desired) {
        await _gateway.schedule(item, at);
        // Record the armed fire time for one-shot standard alarms so a future
        // reconcile can tell whether this delivery already happened.
        if (item.kind == ScheduledKind.standardAlarm &&
            _isOneShot(item.id)) {
          nextArmed[item.id] = at.millisecondsSinceEpoch;
        }
      }
      // Persist only if the armed set actually changed (avoid needless writes).
      if (!_sameMap(armed, nextArmed)) await _writeOneShotArmed(nextArmed);
      state = true;
    } finally {
      _reconciling = false;
    }
  }

  bool _isOneShot(String alarmId) {
    final matches = ref.read(alarmsControllerProvider).where((a) => a.id == alarmId);
    return matches.isNotEmpty && matches.first.days.isEmpty;
  }

  static bool _sameMap(Map<String, int> a, Map<String, int> b) {
    if (a.length != b.length) return false;
    for (final e in a.entries) {
      if (b[e.key] != e.value) return false;
    }
    return true;
  }
}

final notificationServiceProvider =
    NotifierProvider<NotificationService, bool>(NotificationService.new);
