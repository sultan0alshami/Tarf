import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../focus/application/focus_controller.dart';
import '../core/active_time_tracker.dart';
import '../core/prayer_service.dart';
import '../core/precedence.dart';
import '../presentation/show_break.dart';
import 'eyecare_config_controller.dart';
import 'eyecare_live.dart';

/// Hosts the in-app eye-care engine. While the app is in the foreground it
/// accumulates *active* time and, when a break is due and the precedence rules
/// allow it, presents the break overlay automatically — then resets.
///
/// This makes the 20-20-20 core work whenever the app/tab is open. Firing while
/// the app is backgrounded is the job of the native schedulers (P4).
class EyeCareHost extends ConsumerStatefulWidget {
  const EyeCareHost({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<EyeCareHost> createState() => _EyeCareHostState();
}

class _EyeCareHostState extends ConsumerState<EyeCareHost>
    with WidgetsBindingObserver {
  Timer? _timer;
  ActiveTimeTracker? _tracker;
  bool _resumed = true;
  bool _breakShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
  }

  ActiveTimeTracker _ensureTracker() {
    final config = ref.read(eyeCareConfigProvider);
    final t = _tracker;
    if (t != null &&
        t.idleThreshold == config.idleThreshold &&
        t.idleResetThreshold == config.idleResetThreshold) {
      return t;
    }
    return _tracker = ActiveTimeTracker(
      idleThreshold: config.idleThreshold,
      idleResetThreshold: config.idleResetThreshold,
    );
  }

  Future<void> _onTick() async {
    if (_breakShowing) return;
    final config = ref.read(eyeCareConfigProvider);
    final live = ref.read(eyeCareLiveProvider.notifier);
    if (!config.enabled || ref.read(eyeCareLiveProvider).paused) return;

    final tracker = _ensureTracker()
      ..tick(const Duration(seconds: 1), active: _resumed);
    live.setAccumulated(tracker.accumulated);
    if (!tracker.isDue(config.eyeInterval)) return;

    final focus = ref.read(focusControllerProvider);
    final now = DateTime.now();
    var inPrayer = false;
    if (config.prayerPauseEnabled) {
      inPrayer = PrayerService.inWindow(
        latitude: config.prayerLatitude,
        longitude: config.prayerLongitude,
        now: now,
        window: config.prayerPauseWindow,
        method: config.prayerMethod,
        madhab: config.prayerMadhab,
      );
    }
    final state = SchedulerState(
      now: now,
      isScreenOff: !_resumed,
      pomodoroBreakActive: focus.isBreak && focus.running,
      prayerPauseEnabled: config.prayerPauseEnabled,
      inPrayerWindow: inPrayer,
    );
    if (decideBreak(state) != BreakDecision.fire) return;

    // No double-fire guard here: eye-breaks fire on *active screen-time*, not a
    // fixed wall-clock minute, so they are never OS-scheduled in the background.
    // This foreground overlay is the only path that ever shows an eye-break,
    // and there is nothing to collapse against. (Only standard alarms + prayer
    // times have a background path — see AlarmHost._ring.)
    _breakShowing = true;
    try {
      await showEyeBreak(context, ref);
    } finally {
      tracker.reset();
      live.reset();
      _breakShowing = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
