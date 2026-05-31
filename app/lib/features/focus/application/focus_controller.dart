import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../domain/focus_models.dart';

const _cfgKey = 'tarf.focus_config.v1';

/// Persisted Pomodoro configuration.
class FocusConfigController extends Notifier<FocusConfig> {
  @override
  FocusConfig build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_cfgKey);
    if (raw == null) return const FocusConfig();
    try {
      return FocusConfig.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const FocusConfig();
    }
  }

  Future<void> update(FocusConfig config) async {
    state = config;
    await ref
        .read(sharedPreferencesProvider)
        .setString(_cfgKey, jsonEncode(config.toJson()));
  }
}

final focusConfigProvider =
    NotifierProvider<FocusConfigController, FocusConfig>(
  FocusConfigController.new,
);

/// Drives the focus timer with a 1-second ticker. Eye-care breaks live in a
/// separate controller and can never advance, pause, or reset this one.
class FocusController extends Notifier<FocusState> {
  Timer? _timer;

  @override
  FocusState build() {
    ref.onDispose(() => _timer?.cancel());
    return const FocusState();
  }

  FocusConfig get _cfg => ref.read(focusConfigProvider);

  void _ensureTicker() {
    _timer ??= Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!state.running || state.phase == FocusPhase.idle) return;
    state = advanceFocus(state, _cfg, const Duration(seconds: 1));
  }

  /// Starts (or restarts) a work session, optionally bound to a to-do task.
  void startWork({String? taskId}) {
    final d = _cfg.work;
    state = FocusState(
      phase: FocusPhase.work,
      remaining: d,
      totalForPhase: d,
      running: true,
      completedWorkSessions: state.completedWorkSessions,
      taskId: taskId,
    );
    _ensureTicker();
  }

  void pause() => state = state.copyWith(running: false);

  void resume() {
    if (state.phase == FocusPhase.idle) return;
    state = state.copyWith(running: true);
    _ensureTicker();
  }

  /// Skips the rest of the current phase, transitioning immediately.
  void skip() {
    if (state.phase == FocusPhase.idle) return;
    state = advanceFocus(
      state.copyWith(running: true),
      _cfg,
      state.remaining + const Duration(seconds: 1),
    );
    _ensureTicker();
  }

  /// Stops everything and returns to idle (session count preserved for the day).
  void reset() {
    _timer?.cancel();
    _timer = null;
    state = FocusState(completedWorkSessions: state.completedWorkSessions);
  }
}

final focusControllerProvider =
    NotifierProvider<FocusController, FocusState>(FocusController.new);
