import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/settings/settings_controller.dart';
import '../../../core/time/clock.dart';
import '../domain/daily_progress.dart';

const _key = 'tarf.progress.v1';

/// Reactive, persisted day-keyed progress. Other features call [addFocusSession]
/// / [addBreak]; Insights reads the map. (Repository-style API so a Firestore
/// sync layer can later mirror these same writes.)
class ProgressController extends Notifier<Map<String, DailyProgress>> {
  @override
  Map<String, DailyProgress> build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final raw = prefs.getString(_key);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      return decoded.map(
        (k, v) =>
            MapEntry(k, DailyProgress.fromJson(v! as Map<String, Object?>)),
      );
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist(Map<String, DailyProgress> next) async {
    state = next;
    final encoded =
        jsonEncode(next.map((k, v) => MapEntry(k, v.toJson())));
    await ref.read(sharedPreferencesProvider).setString(_key, encoded);
  }

  DailyProgress _today(DateTime now) {
    final key = dayKey(now);
    return state[key] ?? DailyProgress.empty(key);
  }

  Future<void> addFocusSession(DateTime now, int minutes) {
    final t = _today(now);
    return _persist({
      ...state,
      t.day: t.copyWith(
        focusMinutes: t.focusMinutes + minutes,
        sessions: t.sessions + 1,
      ),
    });
  }

  Future<void> addBreak(DateTime now, {required bool taken}) {
    final t = _today(now);
    return _persist({
      ...state,
      t.day: taken
          ? t.copyWith(breaksTaken: t.breaksTaken + 1)
          : t.copyWith(breaksSkipped: t.breaksSkipped + 1),
    });
  }
}

final progressControllerProvider =
    NotifierProvider<ProgressController, Map<String, DailyProgress>>(
  ProgressController.new,
);
