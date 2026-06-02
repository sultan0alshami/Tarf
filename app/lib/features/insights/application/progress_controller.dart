import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/data/tarf_repository.dart';
import '../../../core/time/clock.dart';
import '../domain/daily_progress.dart';

/// Reactive, persisted day-keyed progress. Other features call [addFocusSession]
/// / [addBreak]; Insights reads the map. Writes go through the repository so the
/// Firestore sync layer mirrors these same writes (with per-day MAX merge).
class ProgressController extends Notifier<Map<String, DailyProgress>> {
  @override
  Map<String, DailyProgress> build() {
    final raw = ref.watch(tarfRepositoryProvider).read(StorageKey.progress);
    if (raw is! Map) return {};
    try {
      return raw.cast<String, Object?>().map(
            (k, v) => MapEntry(k, DailyProgress.fromJson(v! as Map<String, Object?>)),
          );
    } catch (_) {
      return {};
    }
  }

  Future<void> _persist(Map<String, DailyProgress> next) async {
    state = next;
    await ref
        .read(tarfRepositoryProvider)
        .write(StorageKey.progress, next.map((k, v) => MapEntry(k, v.toJson())));
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
