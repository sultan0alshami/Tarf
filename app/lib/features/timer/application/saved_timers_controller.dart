import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/data/tarf_repository.dart';
import '../domain/saved_timer.dart';

/// Persisted list of saved timers (label + duration + soundId). Mirrors the
/// AlarmsController persistence pattern, routed through the repository so the
/// cloud mirror sees timer changes (StorageKey.timers -> tarf.saved_timers.v1).
class SavedTimersController extends Notifier<List<SavedTimer>> {
  @override
  List<SavedTimer> build() {
    final raw = ref.watch(tarfRepositoryProvider).read(StorageKey.timers);
    if (raw is! List) return const [];
    try {
      return raw.cast<Map<String, Object?>>().map(SavedTimer.fromJson).toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _persist(List<SavedTimer> next) async {
    state = next;
    await ref
        .read(tarfRepositoryProvider)
        .write(StorageKey.timers, next.map((t) => t.toJson()).toList());
  }

  /// Adds [item] if its id is new, otherwise replaces the timer with that id.
  Future<void> upsert(SavedTimer item) {
    final exists = state.any((t) => t.id == item.id);
    final next = exists
        ? [for (final t in state) if (t.id == item.id) item else t]
        : [...state, item];
    return _persist(next);
  }

  Future<void> remove(String id) =>
      _persist([for (final t in state) if (t.id != id) t]);
}

final savedTimersControllerProvider =
    NotifierProvider<SavedTimersController, List<SavedTimer>>(
  SavedTimersController.new,
);
