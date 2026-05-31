import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/alarms_controller.dart';
import '../domain/alarm_item.dart';
import 'alarm_ringing_screen.dart';

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
  }

  Future<void> _ring(AlarmItem item, DateTime now) async {
    if (_ringing || !mounted) return;
    _ringing = true;
    final navigator = Navigator.of(context, rootNavigator: true);

    void stop() {
      // One-shot alarms switch off after ringing so they don't repeat daily.
      if (item.days.isEmpty && item.enabled) {
        ref.read(alarmsControllerProvider.notifier).toggle(item.id);
      }
      navigator.pop();
    }

    void snooze() {
      _snoozeUntil[item.id] = DateTime.now().add(const Duration(minutes: 5));
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
      _ringing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
