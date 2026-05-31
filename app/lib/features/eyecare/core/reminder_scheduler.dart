import 'dart:async';

import 'package:flutter/foundation.dart';

import 'precedence.dart';

/// A break that is due to be shown.
@immutable
class BreakEvent {
  const BreakEvent({required this.kind, required this.duration});

  final BreakKind kind;
  final Duration duration;

  @override
  bool operator ==(Object other) =>
      other is BreakEvent && other.kind == kind && other.duration == duration;

  @override
  int get hashCode => Object.hash(kind, duration);
}

/// Abstracts the per-platform mechanics of *scheduling* a break and surfacing
/// the OS notification (the visual cue only). Implementations:
///   - MobileScheduler  (flutter_local_notifications + AlarmManager + WorkManager)
///   - DesktopScheduler (timers + tray + local_notifier)
///   - ExtensionBridge  (JS chrome.alarms/notifications via interop)
///   - FakeScheduler    (tests)
///
/// The 20-second break *audio* is NOT handled here — it is played by the app
/// audio layer so that "sound ends exactly when the break ends" holds.
abstract interface class ReminderScheduler {
  Future<void> init();

  /// Schedule the next eye break to become due after [fromNow].
  Future<void> scheduleNextEyeBreak(Duration fromNow);

  /// Cancel any pending scheduled breaks.
  Future<void> cancelAll();

  /// Show the OS notification announcing a break has started (visual cue only).
  Future<void> showBreakNotification(BreakEvent event);

  /// Emits whenever a scheduled break becomes due (platform timer/alarm fired).
  Stream<BreakEvent> get onBreakDue;
}

/// In-memory scheduler for tests and the initial web preview. Records calls and
/// lets tests drive [onBreakDue] manually.
class FakeScheduler implements ReminderScheduler {
  final _controller = StreamController<BreakEvent>.broadcast();

  int initCount = 0;
  int cancelCount = 0;
  Duration? lastScheduledDelay;
  final List<BreakEvent> shownNotifications = [];

  @override
  Future<void> init() async => initCount++;

  @override
  Future<void> scheduleNextEyeBreak(Duration fromNow) async =>
      lastScheduledDelay = fromNow;

  @override
  Future<void> cancelAll() async => cancelCount++;

  @override
  Future<void> showBreakNotification(BreakEvent event) async =>
      shownNotifications.add(event);

  @override
  Stream<BreakEvent> get onBreakDue => _controller.stream;

  /// Test helper: simulate the platform firing a due break.
  void fireBreak(BreakEvent event) => _controller.add(event);

  Future<void> dispose() => _controller.close();
}
