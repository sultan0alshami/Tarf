import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/audio_providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../eyecare/application/eyecare_config_controller.dart';
import '../../eyecare/core/prayer_service.dart';
import '../application/alarms_controller.dart';
import '../domain/alarm_item.dart';
import 'alarm_ringing_screen.dart';
import 'alarm_sound.dart';

/// Foreground alarm watcher. While the app is open it checks every few seconds
/// and, when an enabled alarm becomes due (or a snooze elapses), presents the
/// full-screen ringing modal. Background ringing is the job of native scheduling
/// (an owner task) — this honors the in-app "rings while open" limitation stated
/// in onboarding and on the Alarms screen.
class AlarmHost extends ConsumerStatefulWidget {
  const AlarmHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<AlarmHost> createState() => _AlarmHostState();
}

class _AlarmHostState extends ConsumerState<AlarmHost> {
  Timer? _timer;
  bool _ringing = false;
  AlarmSoundController? _sound;
  final Set<String> _firedThisMinute = {};
  final Map<String, DateTime> _snoozeUntil = {};

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _check());
  }

  String _minuteKey(String id, DateTime now) =>
      '$id ${now.year}-${now.month}-${now.day} ${now.hour}:${now.minute}';

  Future<void> _check() async {
    if (_ringing || !mounted) return;
    final now = DateTime.now();
    final alarms = ref.read(alarmsControllerProvider);

    // 1) A due snooze takes priority.
    for (final entry in _snoozeUntil.entries) {
      if (!now.isBefore(entry.value)) {
        final a = alarms.where((x) => x.id == entry.key && x.enabled);
        if (a.isNotEmpty) {
          _snoozeUntil.remove(entry.key);
          await _ring(a.first, now);
          return;
        }
        _snoozeUntil.remove(entry.key);
        return;
      }
    }

    // 2) A scheduled alarm matching this minute.
    for (final a in alarms) {
      if (!a.enabled) continue;
      final matchesTime = a.hour == now.hour && a.minute == now.minute;
      final appliesToday = a.days.isEmpty || a.days.contains(now.weekday);
      final key = _minuteKey(a.id, now);
      if (matchesTime && appliesToday && !_firedThisMinute.contains(key)) {
        _firedThisMinute.add(key);
        await _ring(a, now);
        return;
      }
    }

    // 3) Computed prayer alarms (Prayer mode), at their times today.
    final cfg = ref.read(eyeCareConfigProvider);
    if (cfg.prayerAlarmsEnabled.isNotEmpty && mounted) {
      final times = PrayerService.timesFor(
        latitude: cfg.prayerLatitude,
        longitude: cfg.prayerLongitude,
        day: now,
        method: cfg.prayerMethod,
        madhab: cfg.prayerMadhab,
      );
      const ids = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
      final l10n = AppLocalizations.of(context);
      for (var i = 0; i < ids.length && i < times.length; i++) {
        if (!cfg.prayerAlarmsEnabled.contains(ids[i])) continue;
        final t = times[i];
        if (t.hour != now.hour || t.minute != now.minute) continue;
        final key = _minuteKey('prayer_${ids[i]}', now);
        if (_firedThisMinute.contains(key)) continue;
        _firedThisMinute.add(key);
        final name = switch (ids[i]) {
          'fajr' => l10n.prayerFajr,
          'dhuhr' => l10n.prayerDhuhr,
          'asr' => l10n.prayerAsr,
          'maghrib' => l10n.prayerMaghrib,
          _ => l10n.prayerIsha,
        };
        await _ring(
          AlarmItem(
            id: 'prayer_${ids[i]}',
            hour: t.hour,
            minute: t.minute,
            label: name,
            days: const {1, 2, 3, 4, 5, 6, 7},
          ),
          now,
        );
        return;
      }
    }
  }

  Future<void> _ring(AlarmItem item, DateTime now) async {
    if (_ringing || !mounted) return;
    _ringing = true;
    final navigator = Navigator.of(context, rootNavigator: true);

    // Loop the alarm's chosen sound + repeating haptic for its ring duration.
    final cfg = ref.read(eyeCareConfigProvider);
    final sound = AlarmSoundController(audio: ref.read(tarfAudioServiceProvider));
    _sound = sound;
    unawaited(sound.start(
      item,
      hapticEnabled: cfg.hapticEnabled,
      playThroughSilent: cfg.loudThroughSilence,
    ));

    void stop() {
      unawaited(sound.stop());
      // One-shot alarms switch off after ringing so they don't repeat daily.
      if (item.days.isEmpty && item.enabled) {
        ref.read(alarmsControllerProvider.notifier).toggle(item.id);
      }
      navigator.pop();
    }

    void snooze() {
      unawaited(sound.stop());
      _snoozeUntil[item.id] =
          DateTime.now().add(Duration(minutes: item.snoozeMinutes));
      navigator.pop();
    }

    try {
      await navigator.push<void>(
        PageRouteBuilder<void>(
          fullscreenDialog: true,
          transitionDuration: const Duration(milliseconds: 280),
          pageBuilder: (_, _, _) => AlarmRingingScreen(
            item: item,
            onStop: stop,
            onSnooze: snooze,
          ),
          transitionsBuilder: (_, animation, _, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } finally {
      // Auto-timeout / OS-popped route also silences the alarm.
      await sound.stop();
      sound.dispose();
      _sound = null;
      _ringing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _sound?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
